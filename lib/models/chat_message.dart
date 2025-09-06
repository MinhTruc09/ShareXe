class ChatMessage {
  final String roomId;
  final String senderEmail;
  final String senderName;
  final String receiverEmail;
  final String content;
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    required this.roomId,
    required this.senderEmail,
    required this.senderName,
    required this.receiverEmail,
    required this.content,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      roomId: json['roomId'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    "roomId": roomId,
    "senderEmail": senderEmail,
    "senderName": senderName,
    "receiverEmail": receiverEmail,
    "content": content,
    "timestamp": timestamp.toIso8601String(),
    "read": read,
  };

  ChatMessage copyWith({
    String? roomId,
    String? senderEmail,
    String? senderName,
    String? receiverEmail,
    String? content,
    DateTime? timestamp,
    bool? read,
  }) {
    return ChatMessage(
      roomId: roomId ?? this.roomId,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}

// Model cho chat room
class ChatRoom {
  final String roomId;
  final String partnerEmail;
  final String partnerName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatRoom({
    required this.roomId,
    required this.partnerEmail,
    required this.partnerName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      roomId: json['roomId'] ?? '',
      partnerEmail: json['partnerEmail'] ?? '',
      partnerName: json['partnerName'] ?? '',
      lastMessage: json['lastMessage'],
      lastMessageTime:
          json['lastMessageTime'] != null
              ? DateTime.parse(json['lastMessageTime'])
              : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "roomId": roomId,
    "partnerEmail": partnerEmail,
    "partnerName": partnerName,
    "lastMessage": lastMessage,
    "lastMessageTime": lastMessageTime?.toIso8601String(),
    "unreadCount": unreadCount,
  };
}
