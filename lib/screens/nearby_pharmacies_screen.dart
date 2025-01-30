import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pharmacy.dart';
import '../services/api_service.dart';
import '../widgets/pharmacy_list_item.dart';
import '../widgets/medication_request_dialog.dart';

class NearbyPharmaciesScreen extends StatefulWidget {
  final ApiService apiService;

  const NearbyPharmaciesScreen({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  State<NearbyPharmaciesScreen> createState() => _NearbyPharmaciesScreenState();
}

class _NearbyPharmaciesScreenState extends State<NearbyPharmaciesScreen> {
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Position? _currentPosition;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      await _loadNearbyPharmacies();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Location services are disabled. Please enable the services';
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied';
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error = 'Location permissions are permanently denied';
      });
      return false;
    }

    return true;
  }

  Future<void> _loadNearbyPharmacies() async {
    if (_currentPosition == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final pharmacies = await widget.apiService.getNearbyPharmacies(_currentPosition!);
      
      final markers = pharmacies.map((pharmacy) {
        return Marker(
          markerId: MarkerId(pharmacy.id.toString()),
          position: LatLng(pharmacy.latitude, pharmacy.longitude),
          infoWindow: InfoWindow(
            title: pharmacy.name,
            snippet: pharmacy.address,
          ),
        );
      }).toSet();

      setState(() {
        _pharmacies = pharmacies;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPharmacies(String query) async {
    if (query.isEmpty) {
      await _loadNearbyPharmacies();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final pharmacies = await widget.apiService.searchPharmacies(query);
      
      final markers = pharmacies.map((pharmacy) {
        return Marker(
          markerId: MarkerId(pharmacy.id.toString()),
          position: LatLng(pharmacy.latitude, pharmacy.longitude),
          infoWindow: InfoWindow(
            title: pharmacy.name,
            snippet: pharmacy.address,
          ),
        );
      }).toSet();

      setState(() {
        _pharmacies = pharmacies;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showRequestDialog(Pharmacy pharmacy) {
    showDialog(
      context: context,
      builder: (context) => MedicationRequestDialog(
        pharmacy: pharmacy,
        apiService: widget.apiService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pharmacies'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search pharmacies...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadNearbyPharmacies();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: _searchPharmacies,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Pharmacy List (top half)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _pharmacies.length,
                      itemBuilder: (context, index) {
                        final pharmacy = _pharmacies[index];
                        return PharmacyListItem(
                          pharmacy: pharmacy,
                          onTap: () => _showRequestDialog(pharmacy),
                          currentPosition: _currentPosition,
                        );
                      },
                    ),
                  ),
                  // Map (bottom half)
                  Expanded(
                    child: _currentPosition == null
                        ? const Center(child: Text('Location not available'))
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 13,
                            ),
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            onMapCreated: (controller) {
                              _mapController = controller;
                            },
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
