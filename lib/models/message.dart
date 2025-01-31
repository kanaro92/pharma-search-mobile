class Message {
  final int id;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? inquiry;

  Message({
    required this.id,
    required this.content,
    required this.createdAt,
    this.sender,
    this.inquiry,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    try {
      return Message(
        id: json['id'] as int,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        sender: json['sender'] as Map<String, dynamic>?,
        inquiry: json['inquiry'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error parsing Message: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'sender': sender,
      'inquiry': inquiry,
    };
  }

  String getSenderName() {
    return sender?['name'] ?? 'Unknown';
  }

  bool isCurrentUser(String currentUserEmail) {
    return sender?['email'] == currentUserEmail;
  }

  int? getSenderId() {
    return sender?['id'] as int?;
  }
}
