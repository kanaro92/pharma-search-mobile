class PharmacyConversation {
  final int pharmacyId;
  final String pharmacyName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  PharmacyConversation({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory PharmacyConversation.fromJson(Map<String, dynamic> json) {
    return PharmacyConversation(
      pharmacyId: json['pharmacyId'],
      pharmacyName: json['pharmacyName'],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
