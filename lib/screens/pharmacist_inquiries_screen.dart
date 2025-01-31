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
    return RoleGuard(
      requiredRole: 'PHARMACIST',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medication Inquiries'),
        ),
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: _loadInquiries,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _inquiries.isEmpty
                  ? const Center(child: Text('No inquiries available'))
                  : ListView.builder(
                      itemCount: _inquiries.length,
                      itemBuilder: (context, index) {
                        final inquiry = _inquiries[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              inquiry.medicationName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inquiry.patientNote,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: inquiry.status == 'PENDING'
                                            ? Colors.orange
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        inquiry.status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormatter.formatDateTime(inquiry.createdAt),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showInquiryDetails(inquiry),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
