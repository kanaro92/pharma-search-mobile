import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/pharmacy.dart';
import 'dart:async';

class MedicationSearchScreen extends StatefulWidget {
  final ApiService apiService;

  const MedicationSearchScreen({Key? key, required this.apiService})
      : super(key: key);

  @override
  _MedicationSearchScreenState createState() => _MedicationSearchScreenState();
}

class _MedicationSearchScreenState extends State<MedicationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchMedications(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await widget.apiService.searchMedications(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching medications: $e'),
            backgroundColor: Colors.red,
          ),
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

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchMedications(query);
    });
  }

  void _showPharmacySelection(String medication) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await widget.apiService.getCurrentPosition();
      final pharmacies = await widget.apiService.getNearbyPharmacies(position);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a Pharmacy for $medication',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: pharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = pharmacies[index];
                      return Card(
                        child: ListTile(
                          title: Text(pharmacy.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pharmacy.address),
                              if (pharmacy.distance != null)
                                Text(
                                  'Distance: ${pharmacy.distance!.toStringAsFixed(2)} km',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _showRequestDialog(medication, pharmacy);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching pharmacies: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRequestDialog(String medication, Pharmacy pharmacy) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request $medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pharmacy: ${pharmacy.name}'),
            const SizedBox(height: 8),
            Text('Address: ${pharmacy.address}'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                hintText: 'Enter any specific requirements or notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await widget.apiService.createMedicationRequest(
                  medication,
                  noteController.text.isEmpty ? null : noteController.text,
                  pharmacy,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medication request sent successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sending request: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
        title: const Text('Search Medications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Medications',
                hintText: 'Enter medication name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Enter a medication name to search'
                              : 'No medications found',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final medication = _searchResults[index];
                          return Card(
                            child: ListTile(
                              title: Text(medication),
                              trailing: ElevatedButton(
                                onPressed: () => _showPharmacySelection(medication),
                                child: const Text('Request'),
                              ),
                            ),
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
