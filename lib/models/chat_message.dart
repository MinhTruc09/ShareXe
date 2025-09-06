class ChatMessage {
  final int? id;
  final String? token;
  final String? roomId;
  final String? senderEmail;
  final String? senderName;
  final String? receiverEmail;
  final String? content;
  final DateTime? timestamp;
  final bool? read;
  final String? status; // sending, sent, read, failed

  ChatMessage({
    this.id,
    this.token,
    this.roomId,
    this.senderEmail,
    this.senderName,
    this.receiverEmail,
    this.content,
    this.timestamp,
    this.read,
    this.status,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseTimestamp(String? timestampStr) {
      if (timestampStr == null) return null;
      try {
        // Handle format: "2025-09-06T18:19:40" (without timezone)
        if (timestampStr.contains('T') && !timestampStr.contains('Z') && !timestampStr.contains('+')) {
          return DateTime.parse(timestampStr + 'Z'); // Add Z to make it UTC
        }
        return DateTime.parse(timestampStr);
      } catch (e) {
        print('❌ Lỗi parse timestamp: $timestampStr, error: $e');
        return null;
      }
    }

    return ChatMessage(
      id: json['id'],
      token: json['token'],
      roomId: json['roomId'],
      senderEmail: json['senderEmail'],
      senderName: json['senderName'],
      receiverEmail: json['receiverEmail'],
      content: json['content'],
      timestamp: parseTimestamp(json['timestamp']),
      read: json['read'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "token": token,
    "roomId": roomId,
    "senderEmail": senderEmail,
    "senderName": senderName,
    "receiverEmail": receiverEmail,
    "content": content,
    "timestamp": timestamp?.toIso8601String(),
    "read": read,
    "status": status,
  };

  ChatMessage copyWith({
    int? id,
    String? token,
    String? roomId,
    String? senderEmail,
    String? senderName,
    String? receiverEmail,
    String? content,
    DateTime? timestamp,
    bool? read,
    String? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      token: token ?? this.token,
      roomId: roomId ?? this.roomId,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      status: status ?? this.status,
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
