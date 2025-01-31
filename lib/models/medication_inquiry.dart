import 'message.dart';

class MedicationInquiry {
  final int id;
  final String medicationName;
  final String patientNote;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? user;
  final List<Message>? messages;

  MedicationInquiry({
    required this.id,
    required this.medicationName,
    required this.patientNote,
    required this.status,
    required this.createdAt,
    this.user,
    this.messages,
  });

  int? get userId => user?['id'] as int?;

  factory MedicationInquiry.fromJson(Map<String, dynamic> json) {
    try {
      List<Message>? messagesList;
      if (json['messages'] != null) {
        messagesList = (json['messages'] as List<dynamic>)
            .map((message) => Message.fromJson(message as Map<String, dynamic>))
            .toList();
      }

      return MedicationInquiry(
        id: json['id'] as int,
        medicationName: json['medicationName'] as String,
        patientNote: json['patientNote'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        user: json['user'] as Map<String, dynamic>?,
        messages: messagesList,
      );
    } catch (e) {
      print('Error parsing MedicationInquiry: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationName': medicationName,
      'patientNote': patientNote,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'user': user,
      'messages': messages?.map((message) => message.toJson()).toList(),
    };
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
