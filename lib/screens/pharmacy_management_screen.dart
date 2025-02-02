import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_guard.dart';
import '../widgets/app_drawer.dart';
import '../models/pharmacy.dart';

class PharmacyManagementScreen extends StatefulWidget {
  final ApiService apiService;

  const PharmacyManagementScreen({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  State<PharmacyManagementScreen> createState() => _PharmacyManagementScreenState();
}

class _PharmacyManagementScreenState extends State<PharmacyManagementScreen> {
  bool _isLoading = false;
  Pharmacy? _pharmacy;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pharmacy = await widget.apiService.getPharmacyData();
      final statistics = await widget.apiService.getPharmacyStatistics();
      
      if (mounted) {
        setState(() {
          _pharmacy = pharmacy;
          _statistics = statistics;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pharmacy data: $e')),
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

  Future<void> _editPharmacy() async {
    if (_pharmacy == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditPharmacyDialog(pharmacy: _pharmacy!),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedPharmacy = await widget.apiService.updatePharmacyData(result);
        setState(() {
          _pharmacy = updatedPharmacy;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pharmacy details updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating pharmacy: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: 'PHARMACIST',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Pharmacy'),
          actions: [
            if (_pharmacy != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editPharmacy,
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pharmacy == null
                ? const Center(child: Text('No pharmacy data available'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pharmacy Details',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Divider(),
                                _buildInfoRow('Name', _pharmacy!.name),
                                _buildInfoRow('Address', _pharmacy!.address),
                                if (_pharmacy!.phone != null)
                                  _buildInfoRow('Phone', _pharmacy!.phone!),
                                if (_pharmacy!.email != null)
                                  _buildInfoRow('Email', _pharmacy!.email!),
                                if (_pharmacy!.openingHours != null)
                                  _buildInfoRow('Opening Hours', _pharmacy!.openingHours!),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_statistics != null) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Statistics',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Divider(),
                                  _buildInfoRow('Total Inquiries', 
                                    _statistics!['totalInquiries']?.toString() ?? '0'),
                                  _buildInfoRow('Pending Inquiries', 
                                    _statistics!['pendingInquiries']?.toString() ?? '0'),
                                  _buildInfoRow('Resolved Inquiries', 
                                    _statistics!['resolvedInquiries']?.toString() ?? '0'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _EditPharmacyDialog extends StatefulWidget {
  final Pharmacy pharmacy;

  const _EditPharmacyDialog({
    required this.pharmacy,
  });

  @override
  _EditPharmacyDialogState createState() => _EditPharmacyDialogState();
}

class _EditPharmacyDialogState extends State<_EditPharmacyDialog> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _openingHoursController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pharmacy.name);
    _addressController = TextEditingController(text: widget.pharmacy.address);
    _phoneController = TextEditingController(text: widget.pharmacy.phone ?? '');
    _emailController = TextEditingController(text: widget.pharmacy.email ?? '');
    _openingHoursController = TextEditingController(text: widget.pharmacy.openingHours ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Pharmacy Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _openingHoursController,
              decoration: const InputDecoration(labelText: 'Opening Hours'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'name': _nameController.text,
              'address': _addressController.text,
              'phone': _phoneController.text,
              'email': _emailController.text,
              'openingHours': _openingHoursController.text,
              'latitude': widget.pharmacy.latitude,
              'longitude': widget.pharmacy.longitude,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
