class Medication {
  final int id;
  final String name;
  final String description;
  final String dosage;
  final String? manufacturer;
  final bool prescriptionRequired;

  Medication({
    required this.id,
    required this.name,
    required this.description,
    required this.dosage,
    this.manufacturer,
    required this.prescriptionRequired,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      dosage: json['dosage'],
      manufacturer: json['manufacturer'],
      prescriptionRequired: json['prescriptionRequired'],
    );
  }
}
