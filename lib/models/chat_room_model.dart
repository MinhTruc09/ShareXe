class ChatRoomModel {
  final String roomId;
  final String partnerEmail;
  final String partnerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? partnerAvatar;

  ChatRoomModel({
    required this.roomId,
    required this.partnerEmail,
    required this.partnerName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.partnerAvatar,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      roomId: json['roomId'] ?? '',
      partnerEmail: json['partnerEmail'] ?? '',
      partnerName: json['partnerName'] ?? 'Unknown',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime:
          json['lastMessageTime'] != null
              ? DateTime.parse(json['lastMessageTime'])
              : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      partnerAvatar: json['partnerAvatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'partnerEmail': partnerEmail,
      'partnerName': partnerName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'partnerAvatar': partnerAvatar,
    };
  }
}
