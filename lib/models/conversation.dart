class Conversation {
  final String id;
  final int user1Id;
  final int user2Id;
  final int? medicationRequestId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lastMessage;
  final bool hasUnreadMessages;

  Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.medicationRequestId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    required this.hasUnreadMessages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      user1Id: json['user1Id'],
      user2Id: json['user2Id'],
      medicationRequestId: json['medicationRequestId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastMessage: json['lastMessage'],
      hasUnreadMessages: json['hasUnreadMessages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'medicationRequestId': medicationRequestId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessage': lastMessage,
      'hasUnreadMessages': hasUnreadMessages,
    };
  }
}
