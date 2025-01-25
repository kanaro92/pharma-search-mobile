import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pharmacy.dart';
import '../services/api_service.dart';
import '../widgets/pharmacy_list_item.dart';
import '../widgets/medication_request_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 12),
        );
      }

      await _fetchNearbyPharmacies();
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchNearbyPharmacies() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pharmacies = await widget.apiService.getNearbyPharmacies(_currentPosition!);
      setState(() {
        _pharmacies = pharmacies;
        _updateMarkers();
      });
    } catch (e) {
      print('Error fetching pharmacies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch nearby pharmacies')),
      );
    } finally {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pharmacies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
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
                    setState(() {
                      _pharmacies = pharmacies;
                      _updateMarkers();
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to search pharmacies')),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Left side: Pharmacy list
                Expanded(
                  flex: 1,
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
                            );
                          },
                        ),
                ),
                // Right side: Map
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation ?? const LatLng(0, 0),
                          zoom: 12,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (_pharmacies.isNotEmpty) {
                            _updateMarkers();
                          }
                        },
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
    );
  }
}
