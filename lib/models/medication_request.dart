import 'package:flutter/material.dart';
import 'user.dart';
import 'pharmacy.dart';

enum RequestStatus {
  PENDING,
  ACCEPTED,
  REJECTED,
  COMPLETED,
  CANCELLED
}

class MedicationRequest {
  final int id;
  final String medicationName;
  final int? quantity;
  final String? note;
  final RequestStatus status;
  final User user;
  final Pharmacy? pharmacy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicationRequest({
    required this.id,
    required this.medicationName,
    this.quantity,
    this.note,
    required this.status,
    required this.user,
    this.pharmacy,
    required this.createdAt,
    this.updatedAt,
  });

  factory MedicationRequest.fromJson(Map<String, dynamic> json) {
    return MedicationRequest(
      id: json['id'],
      medicationName: json['medicationName'],
      quantity: json['quantity'],
      note: json['note'],
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'].toString().toUpperCase(),
        orElse: () => RequestStatus.PENDING,
      ),
      user: User.fromJson(json['user']),
      pharmacy: json['pharmacy'] != null ? Pharmacy.fromJson(json['pharmacy']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  String get statusText {
    return status.toString().split('.').last.toLowerCase();
  }

  Color get statusColor {
    switch (status) {
      case RequestStatus.PENDING:
        return Colors.orange;
      case RequestStatus.ACCEPTED:
        return Colors.green;
      case RequestStatus.REJECTED:
        return Colors.red;
      case RequestStatus.COMPLETED:
        return Colors.blue;
      case RequestStatus.CANCELLED:
        return Colors.grey;
    }
  }
}
