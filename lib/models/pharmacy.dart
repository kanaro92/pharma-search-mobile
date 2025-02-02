class Pharmacy {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? distance;
  final String? phone;
  final String? email;
  final String? openingHours;
  final Map<String, dynamic>? statistics;

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.phone,
    this.email,
    this.openingHours,
    this.statistics,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      openingHours: json['openingHours'] as String?,
      statistics: json['statistics'] as Map<String, dynamic>?,
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
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (openingHours != null) 'openingHours': openingHours,
      if (statistics != null) 'statistics': statistics,
    };
  }

  @override
  String toString() {
    return 'Pharmacy{id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude, distance: $distance, phone: $phone, email: $email, openingHours: $openingHours, statistics: $statistics}';
  }
}
