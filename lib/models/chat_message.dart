import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessage {
  final String id;
  final String content;
  final int senderId;
  final int receiverId;
  final DateTime timestamp;
  final bool isRead;
  final int? medicationRequestId;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.timestamp,
    required this.isRead,
    this.medicationRequestId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      content: json['content'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['read'],
      medicationRequestId: json['medicationRequestId'],
    );
  }

  types.Message toFlutterChatMessage(bool isCurrentUser) {
    return types.TextMessage(
      id: id,
      text: content,
      author: types.User(
        id: senderId.toString(),
      ),
      createdAt: timestamp.millisecondsSinceEpoch,
      status: isRead ? types.Status.seen : types.Status.sent,
    );
  }
}
