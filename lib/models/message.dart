class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime timestamp;
  final bool read;
  final int? medicationRequestId;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.read,
    this.medicationRequestId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      read: json['read'],
      medicationRequestId: json['medicationRequestId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'medicationRequestId': medicationRequestId,
    };
  }
}
