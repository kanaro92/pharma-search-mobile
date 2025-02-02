import 'package:flutter/material.dart';
import '../models/medication_inquiry.dart';
import '../services/inquiry_service.dart';
import '../widgets/inquiry_list_item.dart';
import '../widgets/inquiries_list.dart';

class MyInquiriesScreen extends StatefulWidget {
  const MyInquiriesScreen({Key? key}) : super(key: key);

  @override
  State<MyInquiriesScreen> createState() => _MyInquiriesScreenState();
}

class _MyInquiriesScreenState extends State<MyInquiriesScreen> {
  late Future<List<MedicationInquiry>> _inquiriesFuture;
  final _inquiryService = InquiryService();

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  void _loadInquiries() {
    _inquiriesFuture = _inquiryService.getUserInquiries();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Search Medications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search TextField
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search medications...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes TextField
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Additional notes for the pharmacist...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Send Button
                  ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send Inquiry to Pharmacists'),
                  ),
                ],
              ),
            ),
            // My Inquiries Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My Inquiries',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Inquiries List
            Expanded(
              child: FutureBuilder<List<MedicationInquiry>>(
                future: _inquiriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading inquiries',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your internet connection and try again.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _loadInquiries();
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final inquiries = snapshot.data ?? [];

                  if (inquiries.isEmpty) {
                    return Center(
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
                              'Start by searching for medications and sending inquiries to nearby pharmacies.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return InquiriesList(
                    inquiries: inquiries,
                    isLoading: false,
                    onRefresh: () async {
                      setState(() {
                        _loadInquiries();
                      });
                    },
                    onInquiryTap: (inquiry) {
                      Navigator.pushNamed(
                        context,
                        '/inquiry-detail',
                        arguments: inquiry,
                      ).then((_) {
                        setState(() {
                          _loadInquiries();
                        });
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
