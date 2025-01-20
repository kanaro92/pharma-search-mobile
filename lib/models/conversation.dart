class Conversation {
  final int id;
  final int otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnreadMessages;
  final int unreadCount;
  final String? otherUserAvatar;
  final int? medicationRequestId;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.hasUnreadMessages,
    required this.unreadCount,
    this.otherUserAvatar,
    this.medicationRequestId,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      otherUserId: json['otherUserId'],
      otherUserName: json['otherUserName'],
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      hasUnreadMessages: json['hasUnreadMessages'],
      unreadCount: json['unreadCount'],
      otherUserAvatar: json['otherUserAvatar'],
      medicationRequestId: json['medicationRequestId'],
    );
  }
}
