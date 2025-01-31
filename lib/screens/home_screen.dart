import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/pharmacy.dart';
import '../services/api_service.dart';
import '../utils/role_guard.dart';
import '../widgets/pharmacy_list_item.dart';
import '../widgets/medication_request_dialog.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services in your ${kIsWeb ? 'browser' : 'device'} settings.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please allow location access.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please reset permissions in your ${kIsWeb ? 'browser' : 'device'} settings.');
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!_mounted) return;

      setState(() {
        _currentPosition = position;
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Update map camera position
      if (_mapController != null && _currentLocation != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }

      // Fetch nearby pharmacies
      await _fetchNearbyPharmacies();
    } catch (e) {
      if (!_mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
          action: kIsWeb ? null : SnackBarAction(
            label: 'Settings',
            onPressed: () async {
              await Geolocator.openLocationSettings();
            },
          ),
        ),
      );
    } finally {
      if (!_mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyPharmacies() async {
    if (_currentPosition == null || !_mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pharmacies = await widget.apiService.getNearbyPharmacies(_currentPosition!);
      if (!_mounted) return;

      setState(() {
        _pharmacies = pharmacies;
        _updateMarkers();
      });
    } catch (e) {
      if (!_mounted) return;

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch nearby pharmacies')),
      );
    } finally {
      if (!_mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMarkers() {
    Set<Marker> markers = {};

    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    for (var pharmacy in _pharmacies) {
      markers.add(
        Marker(
          markerId: MarkerId(pharmacy.id.toString()),
          position: LatLng(pharmacy.latitude, pharmacy.longitude),
          infoWindow: InfoWindow(
            title: pharmacy.name,
            snippet: pharmacy.address,
          ),
          onTap: () {
            _showPharmacyDetails(pharmacy);
          },
        ),
      );
    }

    if (!_mounted) return;

    setState(() {
      _markers = markers;
    });

    if (_pharmacies.isNotEmpty && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _getBounds(_pharmacies),
          50.0,
        ),
      );
    }
  }

  LatLngBounds _getBounds(List<Pharmacy> pharmacies) {
    if (_currentLocation == null || pharmacies.isEmpty) {
      throw Exception('No location data available');
    }

    double minLat = _currentLocation!.latitude;
    double maxLat = _currentLocation!.latitude;
    double minLng = _currentLocation!.longitude;
    double maxLng = _currentLocation!.longitude;

    for (var pharmacy in pharmacies) {
      if (pharmacy.latitude < minLat) minLat = pharmacy.latitude;
      if (pharmacy.latitude > maxLat) maxLat = pharmacy.latitude;
      if (pharmacy.longitude < minLng) minLng = pharmacy.longitude;
      if (pharmacy.longitude > maxLng) maxLng = pharmacy.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _showPharmacyDetails(Pharmacy pharmacy) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pharmacy.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(pharmacy.address),
            const SizedBox(height: 8),
            if (pharmacy.distance != null)
              Text('Distance: ${pharmacy.distance?.toStringAsFixed(2)} km'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMedicationRequestDialog(pharmacy);
                  },
                  icon: const Icon(Icons.medical_services),
                  label: const Text('Request Medication'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=${pharmacy.latitude},${pharmacy.longitude}',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicationRequestDialog(Pharmacy pharmacy) {
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
    return RoleGuard(
      requiredRole: 'USER',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Pharmacies'),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
            ),
          ],
        ),
        drawer: const AppDrawer(),
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
                      _fetchNearbyPharmacies();
                    },
                  ),
                ),
                onSubmitted: (value) async {
                  if (value.isEmpty) {
                    await _fetchNearbyPharmacies();
                  } else {
                    setState(() {
                      _isLoading = true;
                    });
                    try {
                      final pharmacies = await widget.apiService.searchPharmacies(value);
                      if (!_mounted) return;

                      setState(() {
                        _pharmacies = pharmacies;
                        _updateMarkers();
                      });
                    } catch (e) {
                      if (!_mounted) return;

                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to search pharmacies')),
                      );
                    } finally {
                      if (!_mounted) return;

                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  // Top half: Pharmacy list
                  Expanded(
                    child: _pharmacies.isEmpty && !_isLoading
                        ? const Center(
                            child: Text('No pharmacies found nearby'),
                          )
                        : ListView.builder(
                            itemCount: _pharmacies.length,
                            itemBuilder: (context, index) {
                              final pharmacy = _pharmacies[index];
                              return PharmacyListItem(
                                pharmacy: pharmacy,
                                onRequestMedication: () => _showMedicationRequestDialog(pharmacy),
                                currentPosition: _currentPosition,
                              );
                            },
                          ),
                  ),
                  // Bottom half: Map
                  Expanded(
                    child: Stack(
                      children: [
                        if (_currentLocation != null) // Only show map when we have location
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _currentLocation!,
                              zoom: 15,
                            ),
                            markers: _markers,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            mapToolbarEnabled: true,
                            onMapCreated: (GoogleMapController controller) {
                              setState(() {
                                _mapController = controller;
                              });
                              if (_pharmacies.isNotEmpty) {
                                _updateMarkers();
                              }
                            },
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(),
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
    );
  }
}
