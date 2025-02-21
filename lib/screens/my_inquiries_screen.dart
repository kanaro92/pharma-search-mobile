import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_guard.dart';
import '../models/medication_inquiry.dart';
import '../widgets/app_drawer.dart';
import '../widgets/inquiries_list.dart';
import '../l10n/app_localizations.dart';
import './inquiry_conversations_screen.dart';

class MyInquiriesScreen extends StatefulWidget {
  final ApiService apiService;

  const MyInquiriesScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _MyInquiriesScreenState createState() => _MyInquiriesScreenState();
}

class _MyInquiriesScreenState extends State<MyInquiriesScreen> {
  List<MedicationInquiry> _inquiries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  Future<void> _loadInquiries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final inquiries = await widget.apiService.getMyMedicationInquiries();
      setState(() {
        _inquiries = inquiries;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.get('errorLoadingInquiries')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showInquiryDetails(MedicationInquiry inquiry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InquiryConversationsScreen(
          apiService: widget.apiService,
          inquiry: inquiry,
        ),
      ),
    ).then((_) => _loadInquiries());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RoleGuard(
      requiredRole: 'USER',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            AppLocalizations.get('myInquiries'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.get('recentInquiries'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Inquiries List
              Expanded(
                child: InquiriesList(
                  inquiries: _inquiries,
                  isLoading: _isLoading,
                  onRefresh: _loadInquiries,
                  onInquiryTap: _showInquiryDetails,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
