class Pharmacy {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phoneNumber;
  final double? distance;  // Distance in kilometers

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    this.distance,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    try {
      print('Converting JSON to Pharmacy: $json'); // Debug print
      return Pharmacy(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        phoneNumber: json['phoneNumber'] as String,
        distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      );
    } catch (e) {
      print('Error creating Pharmacy from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'distance': distance,
    };
  }

  @override
  String toString() {
    return 'Pharmacy{id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude}';
  }
}
