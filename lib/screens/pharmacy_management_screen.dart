import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/role_guard.dart';
import '../widgets/app_drawer.dart';
import '../models/pharmacy.dart';
import '../l10n/app_localizations.dart';

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
    final theme = Theme.of(context);
    
    return RoleGuard(
      requiredRole: 'PHARMACIST',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            AppLocalizations.get('myPharmacy'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_pharmacy != null)
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: AppLocalizations.get('editPharmacyDetails'),
                onPressed: _editPharmacy,
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: AppLocalizations.get('refreshData'),
              onPressed: _loadData,
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : _pharmacy == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_rounded,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pharmacy data available',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pharmacy Details Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.local_pharmacy_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.get('pharmacyDetails'),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      context: context,
                                      icon: Icons.store_rounded,
                                      label: AppLocalizations.get('name'),
                                      value: _pharmacy!.name,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow(
                                      context: context,
                                      icon: Icons.location_on_rounded,
                                      label: AppLocalizations.get('address'),
                                      value: _pharmacy!.address,
                                    ),
                                    const SizedBox(height: 16),
                                    if (_pharmacy!.phone != null)
                                      _buildInfoRow(
                                        context: context,
                                        icon: Icons.phone_rounded,
                                        label: AppLocalizations.get('phone'),
                                        value: _pharmacy!.phone!,
                                      ),
                                    const SizedBox(height: 16),
                                    if (_pharmacy!.email != null)
                                      _buildInfoRow(
                                        context: context,
                                        icon: Icons.email_rounded,
                                        label: AppLocalizations.get('email'),
                                        value: _pharmacy!.email!,
                                      ),
                                    const SizedBox(height: 16),
                                    if (_pharmacy!.openingHours != null)
                                      _buildInfoRow(
                                        context: context,
                                        icon: Icons.access_time_rounded,
                                        label: AppLocalizations.get('openingHours'),
                                        value: _pharmacy!.openingHours!,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Statistics Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.analytics_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.get('statistics'),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_statistics != null)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.question_answer_rounded,
                                          label: AppLocalizations.get('total'),
                                          value: _statistics!['totalInquiries']?.toString() ?? '0',
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.pending_actions_rounded,
                                          label: AppLocalizations.get('pharmacyPending'),
                                          value: _statistics!['pendingInquiries']?.toString() ?? '0',
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.check_circle_rounded,
                                          label: AppLocalizations.get('pharmacyResolved'),
                                          value: _statistics!['resolvedInquiries']?.toString() ?? '0',
                                          color: Colors.green,
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
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
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
      title: Text(AppLocalizations.get('editPharmacyDetails')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: AppLocalizations.get('name')),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: AppLocalizations.get('address')),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: AppLocalizations.get('phone')),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: AppLocalizations.get('email')),
            ),
            TextField(
              controller: _openingHoursController,
              decoration: InputDecoration(labelText: AppLocalizations.get('openingHours')),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.get('cancel')),
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
          child: Text(AppLocalizations.get('save')),
        ),
      ],
    );
  }
}
