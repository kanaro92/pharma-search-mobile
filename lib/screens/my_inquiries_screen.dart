import 'package:flutter/material.dart';
import '../models/medication_inquiry.dart';
import '../services/inquiry_service.dart';
import '../widgets/inquiry_list_item.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Medication Inquiries',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: FutureBuilder<List<MedicationInquiry>>(
          future: _inquiriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
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
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading inquiries',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.8),
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Inquiries Yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by searching for medications and sending inquiries to nearby pharmacies.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/medication-search');
                        },
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Search Medications'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                setState(() {
                  _loadInquiries();
                });
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: inquiries.length,
                itemBuilder: (context, index) {
                  final inquiry = inquiries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InquiryListItem(
                      inquiry: inquiry,
                      onTap: () {
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
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
