import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_guard.dart';
import '../models/medication_inquiry.dart';
import '../widgets/app_drawer.dart';
import '../widgets/inquiries_list.dart';
import './inquiry_detail_screen.dart';

class MedicationSearchScreen extends StatefulWidget {
  final ApiService apiService;

  const MedicationSearchScreen({Key? key, required this.apiService})
      : super(key: key);

  @override
  _MedicationSearchScreenState createState() => _MedicationSearchScreenState();
}

class _MedicationSearchScreenState extends State<MedicationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<MedicationInquiry> _inquiries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    super.dispose();
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
          content: Text('Error loading inquiries: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createInquiry() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a medication name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await widget.apiService.createMedicationInquiry(
        _searchController.text.trim(),
        _noteController.text.trim(),
      );

      if (success) {
        // Reset form fields
        _searchController.clear();
        _noteController.clear();
        
        // Refresh the inquiries list
        await _loadInquiries();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inquiry sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send inquiry'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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

  void _showInquiryDetails(MedicationInquiry inquiry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InquiryDetailScreen(
          apiService: widget.apiService,
          inquiry: inquiry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RoleGuard(
      requiredRole: 'USER',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            'Search Medications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        drawer: const AppDrawer(),
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
                        controller: _searchController,
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
                        controller: _noteController,
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
                      onPressed: _isLoading ? null : _createInquiry,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_isLoading ? 'Sending...' : 'Send Inquiry to Pharmacists'),
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
                      'Recent Inquiries',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
