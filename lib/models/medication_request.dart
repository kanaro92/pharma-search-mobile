import 'package:flutter/material.dart';
import 'medication.dart';
import 'pharmacy.dart';

enum RequestStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled
}

class MedicationRequest {
  final int id;
  final Medication medication;
  final Pharmacy pharmacy;
  final int quantity;
  final String? note;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool hasUnreadMessages;

  MedicationRequest({
    required this.id,
    required this.medication,
    required this.pharmacy,
    required this.quantity,
    this.note,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.hasUnreadMessages,
  });

  factory MedicationRequest.fromJson(Map<String, dynamic> json) {
    return MedicationRequest(
      id: json['id'],
      medication: Medication.fromJson(json['medication']),
      pharmacy: Pharmacy.fromJson(json['pharmacy']),
      quantity: json['quantity'],
      note: json['note'],
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
      hasUnreadMessages: json['hasUnreadMessages'] ?? false,
    );
  }

  String get statusText {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.completed:
        return Colors.blue;
      case RequestStatus.cancelled:
        return Colors.grey;
    }
  }
}
