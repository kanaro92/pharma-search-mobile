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
        backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
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
                        Icons.medication_liquid_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.get('medicationInquiries'),
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
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : _inquiries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medication_rounded,
                                  size: 64,
                                  color: theme.colorScheme.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.get('noInquiriesTitle'),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.get('noInquiriesMessage'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: theme.colorScheme.primary,
                            onRefresh: _loadInquiries,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _inquiries.length,
                              itemBuilder: (context, index) {
                                final inquiry = _inquiries[index];
                                final isPending = inquiry.status == 'PENDING';
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Material(
                                    color: Colors.white,
                                    elevation: 1,
                                    shadowColor: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => _showInquiryDetails(inquiry),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                                    width: 0.5,
                                                  ),
                                                ),
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
                                                      Icons.medication_rounded,
                                                      color: theme.colorScheme.primary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      inquiry.medicationName,
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: (isPending ? Colors.orange : Colors.green)
                                                          .withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          isPending
                                                              ? Icons.pending_rounded
                                                              : Icons.check_circle_rounded,
                                                          color: isPending ? Colors.orange : Colors.green,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          AppLocalizations.get(isPending ? 'pending' : 'responded'),
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            color: isPending ? Colors.orange : Colors.green,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (inquiry.patientNote.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary.withOpacity(0.05),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                                      width: 0.5,
                                                    ),
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
                                              ),
                                            Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.access_time_rounded,
                                                        size: 16,
                                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        DateFormatter.formatTimeAgo(inquiry.createdAt),
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 24),
                                                  if (!isPending && inquiry.respondingPharmacies != null)
                                                    Flexible(
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.local_pharmacy_rounded,
                                                            size: 16,
                                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Flexible(
                                                            child: Text(
                                                              '${inquiry.respondingPharmacies?.length ?? 0} ${AppLocalizations.get('pharmaciesResponded')}',
                                                              style: theme.textTheme.bodySmall?.copyWith(
                                                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
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
            ],
          ),
        ),
      ),
    );
  }
}
