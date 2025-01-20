import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pharmacy.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../providers/auth_provider.dart';
import '../screens/search_screen.dart'; 
import '../screens/conversations_screen.dart'; 
import '../screens/requests_screen.dart'; 

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  late final ApiService _apiService;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Pharmacy> _nearbyPharmacies = [];
  bool _isLoading = false;
  bool hasUnreadMessages = false; 
  bool hasUnreadRequests = false; 
  bool _initialized = false;
  
  // Add default position for Paris, France
  static const LatLng _defaultLocation = LatLng(48.8566, 2.3522);
  LatLng _currentLocation = _defaultLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _apiService = Provider.of<AuthProvider>(context).apiService;
      _initialized = true;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      _currentLocation = LatLng(position.latitude, position.longitude);
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLocation,
              zoom: 15,
            ),
          ),
        );
      }

      // Fetch nearby pharmacies
      final pharmacies = await _apiService.findNearbyPharmacies(
        position.latitude,
        position.longitude,
      );

      print('Received pharmacies: $pharmacies');

      if (pharmacies.isEmpty) {
        print('No pharmacies found nearby');
        setState(() {
          _nearbyPharmacies = [];
          _markers = {};
        });
        return;
      }

      final newMarkers = pharmacies.map((pharmacy) {
        print('Creating marker for pharmacy: ${pharmacy.name} at ${pharmacy.latitude}, ${pharmacy.longitude}');
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
        _nearbyPharmacies = pharmacies;
        _markers = newMarkers;
        print('Created ${_markers.length} markers');
      });
    } catch (e) {
      print('Error in _getCurrentLocation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pharmacies'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.message),
                if (hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.medical_services),
                if (hasUnreadRequests)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 1,
                  child: _nearbyPharmacies.isEmpty
                      ? const Center(
                          child: Text('No pharmacies found nearby'),
                        )
                      : ListView.builder(
                          itemCount: _nearbyPharmacies.length,
                          itemBuilder: (context, index) {
                            final pharmacy = _nearbyPharmacies[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(pharmacy.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pharmacy.address),
                                    if (pharmacy.distance != null)
                                      Text(
                                        '${pharmacy.distance!.toStringAsFixed(1)} km away',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.directions),
                                  onPressed: () async {
                                    final url = Uri.parse(
                                      'https://www.google.com/maps/dir/?api=1&destination=${pharmacy.latitude},${pharmacy.longitude}'
                                    );
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Could not open directions'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                onTap: () {
                                  if (_mapController != null) {
                                    _mapController!.animateCamera(
                                      CameraUpdate.newLatLng(
                                        LatLng(
                                          pharmacy.latitude,
                                          pharmacy.longitude,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
                Expanded(
                  flex: 1,
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      setState(() {
                        _mapController = controller;
                      });
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: _currentLocation,
                            zoom: 15,
                          ),
                        ),
                      );
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation,
                      zoom: 15,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ],
            ),
    );
  }
}
