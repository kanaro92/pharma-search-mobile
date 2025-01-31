import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_guard.dart';
import '../widgets/app_drawer.dart';
import '../models/medication_inquiry.dart';
import 'inquiry_response_screen.dart';

class PharmacistHomeScreen extends StatefulWidget {
  final ApiService apiService;

  const PharmacistHomeScreen({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  State<PharmacistHomeScreen> createState() => _PharmacistHomeScreenState();
}

class _PharmacistHomeScreenState extends State<PharmacistHomeScreen> {
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
      _inquiries = await widget.apiService.getPharmacistInquiries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inquiries: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _respondToInquiry(MedicationInquiry inquiry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InquiryResponseScreen(
          apiService: widget.apiService,
          inquiry: inquiry,
        ),
      ),
    );

    if (result == true) {
      _loadInquiries(); // Reload inquiries after response
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: 'PHARMACIST',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medication Inquiries'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadInquiries,
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _inquiries.isEmpty
                ? const Center(
                    child: Text(
                      'No medication inquiries yet',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _inquiries.length,
                    itemBuilder: (context, index) {
                      final inquiry = _inquiries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            inquiry.medicationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Status: ${inquiry.status}',
                            style: TextStyle(
                              color: inquiry.status == 'PENDING'
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Patient Note: ${inquiry.patientNote}'),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (inquiry.status == 'PENDING')
                                        ElevatedButton(
                                          onPressed: () => _respondToInquiry(inquiry),
                                          child: const Text('Respond'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
