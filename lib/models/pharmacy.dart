class Pharmacy {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distance;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (distance != null) 'distance': distance,
    };
  }

  @override
  String toString() {
    return 'Pharmacy{id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude, distance: $distance}';
  }
}
