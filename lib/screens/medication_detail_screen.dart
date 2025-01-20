import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medication.dart';
import '../models/pharmacy.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailScreen({Key? key, required this.medication})
      : super(key: key);

  @override
  _MedicationDetailScreenState createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  List<Pharmacy> _availablePharmacies = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailablePharmacies();
  }

  Future<void> _loadAvailablePharmacies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      final pharmacies = await _apiService.findNearbyPharmacies(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _availablePharmacies = pharmacies;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading pharmacies: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRequestDialog(Pharmacy pharmacy) {
    final quantityController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pharmacy: ${pharmacy.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement medication request
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request sent successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medication details
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description: ${widget.medication.description}'),
                          const SizedBox(height: 8),
                          Text('Dosage: ${widget.medication.dosage}'),
                          if (widget.medication.manufacturer != null) ...[
                            const SizedBox(height: 8),
                            Text(
                                'Manufacturer: ${widget.medication.manufacturer}'),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Prescription Required: '),
                              Icon(
                                widget.medication.prescriptionRequired
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: widget.medication.prescriptionRequired
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Available pharmacies
                  Text(
                    'Available at Nearby Pharmacies',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  if (_availablePharmacies.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No pharmacies found nearby'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _availablePharmacies.length,
                      itemBuilder: (context, index) {
                        final pharmacy = _availablePharmacies[index];
                        return Card(
                          child: ListTile(
                            title: Text(pharmacy.name),
                            subtitle: Text(pharmacy.address),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          otherUserId: pharmacy.id,
                                          otherUserName: pharmacy.name,
                                          medicationRequestId: null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () => _showRequestDialog(pharmacy),
                                  child: const Text('Request'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
