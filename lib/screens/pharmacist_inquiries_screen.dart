import 'package:flutter/material.dart';
import '../models/medication_inquiry.dart';
import '../services/api_service.dart';
import '../utils/role_guard.dart';
import '../widgets/app_drawer.dart';
import 'pharmacist_inquiry_detail_screen.dart';
import '../utils/date_formatter.dart';
import '../l10n/app_localizations.dart';

class PharmacistInquiriesScreen extends StatefulWidget {
  final ApiService apiService;

  const PharmacistInquiriesScreen({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  _PharmacistInquiriesScreenState createState() => _PharmacistInquiriesScreenState();
}

class _PharmacistInquiriesScreenState extends State<PharmacistInquiriesScreen> {
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
      final inquiries = await widget.apiService.getPharmacistInquiries();
      setState(() {
        _inquiries = inquiries;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading inquiries: $e')),
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
        builder: (context) => PharmacistInquiryDetailScreen(
          apiService: widget.apiService,
          inquiry: inquiry,
        ),
      ),
    ).then((_) => _loadInquiries()); // Refresh list when returning
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RoleGuard(
      requiredRole: 'PHARMACIST',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            AppLocalizations.get('medicationInquiries'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: AppLocalizations.get('refreshInquiries'),
              onPressed: _loadInquiries,
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _inquiries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.get('noInquiriesFound'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loadInquiries,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(AppLocalizations.get('refreshInquiries')),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadInquiries,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _inquiries.length,
                        itemBuilder: (context, index) {
                          final inquiry = _inquiries[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.medication_rounded),
                              ),
                              title: Text(
                                inquiry.medicationName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(inquiry.patientNote),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.formatTimeAgo(inquiry.createdAt),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (inquiry.status == 'PENDING'
                                          ? Colors.orange
                                          : Colors.green)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  inquiry.status == 'PENDING'
                                      ? AppLocalizations.get('inquiryPending')
                                      : AppLocalizations.get('inquiryResponded'),
                                  style: TextStyle(
                                    color: inquiry.status == 'PENDING'
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () => _showInquiryDetails(inquiry),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
