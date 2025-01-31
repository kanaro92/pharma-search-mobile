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
      appBar: AppBar(
        title: const Text('My Inquiries'),
      ),
      body: FutureBuilder<List<MedicationInquiry>>(
        future: _inquiriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading inquiries',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadInquiries();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final inquiries = snapshot.data ?? [];

          if (inquiries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No inquiries yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your medication inquiries will appear here',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadInquiries();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: inquiries.length,
              itemBuilder: (context, index) {
                final inquiry = inquiries[index];
                return InquiryListItem(
                  inquiry: inquiry,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/inquiry-detail',
                      arguments: inquiry,
                    ).then((_) {
                      // Reload inquiries when returning from detail screen
                      setState(() {
                        _loadInquiries();
                      });
                    });
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
