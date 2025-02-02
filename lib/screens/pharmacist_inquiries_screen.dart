import 'package:flutter/material.dart';
import '../models/medication_inquiry.dart';
import '../services/api_service.dart';
import '../utils/role_guard.dart';
import '../widgets/app_drawer.dart';
import 'pharmacist_inquiry_detail_screen.dart';
import '../utils/date_formatter.dart';

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
          title: const Text(
            'Medication Inquiries',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        drawer: const AppDrawer(),
        body: SafeArea(
          child: RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: _loadInquiries,
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _inquiries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 64,
                                color: theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Inquiries Yet',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You will see medication inquiries from patients here.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: _inquiries.length,
                        itemBuilder: (context, index) {
                          final inquiry = _inquiries[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 2,
                              margin: EdgeInsets.zero,
                              child: InkWell(
                                onTap: () => _showInquiryDetails(inquiry),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.medication_rounded,
                                              color: theme.colorScheme.primary,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  inquiry.medicationName,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormatter.formatDate(inquiry.createdAt),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: (inquiry.status == 'PENDING'
                                                      ? Colors.orange
                                                      : Colors.green)
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              inquiry.status,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: inquiry.status == 'PENDING'
                                                    ? Colors.orange
                                                    : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (inquiry.patientNote.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.notes_rounded,
                                                size: 16,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  inquiry.patientNote,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
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
