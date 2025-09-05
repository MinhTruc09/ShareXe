class ChatMessage {
  final String? token;
  final String? senderEmail;
  final String? receiverEmail;
  final String? senderName;
  final String? content;
  final String? roomId;
  final DateTime? timestamp;
  final bool? read;

  final int? id;
  final String? status; // 'sending', 'sent', 'delivered', 'read', 'failed'

  ChatMessage({
    this.token,
    this.senderEmail,
    this.receiverEmail,
    this.senderName,
    this.content,
    this.roomId,
    this.timestamp,
    this.read,
    this.id,
    this.status,
  });

  factory ChatMessage.fromApiJson(Map<String, dynamic> json) {
    return ChatMessage(
      token: json['token'],
      senderEmail: json['senderEmail'],
      receiverEmail: json['receiverEmail'],
      senderName: json['senderName'],
      content: json['content'],
      roomId: json['roomId'],
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      read: json['read'],
      id: json['id'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'senderName': senderName,
      'content': content,
      'roomId': roomId,
      'timestamp': timestamp?.toIso8601String(),
      'read': read,
      'id': id,
      'status': status,
    };
  }

  ChatMessage copyWith({
    String? token,
    String? senderEmail,
    String? receiverEmail,
    String? senderName,
    String? content,
    String? roomId,
    DateTime? timestamp,
    bool? read,
    int? id,
    String? status,
  }) {
    return ChatMessage(
      token: token ?? this.token,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      roomId: roomId ?? this.roomId,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      id: id ?? this.id,
      status: status ?? this.status,
    );
  }
}

class ChatRoomUI {
  final String roomId;
  final String otherUserEmail;
  final String otherUserName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? partnerAvatar;

  ChatRoomUI({
    required this.roomId,
    required this.otherUserEmail,
    required this.otherUserName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.partnerAvatar,
  });

  factory ChatRoomUI.fromApiJson(Map<String, dynamic> json) {
    return ChatRoomUI(
      roomId: json['roomId'] ?? '',
      otherUserEmail: json['otherUserEmail'] ?? '',
      otherUserName: json['otherUserName'] ?? '',
      lastMessage: json['lastMessage'],
      lastMessageTime:
          json['lastMessageTime'] != null
              ? DateTime.parse(json['lastMessageTime'])
              : null,
      unreadCount: json['unreadCount'] ?? 0,
      partnerAvatar: json['partnerAvatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'otherUserEmail': otherUserEmail,
      'otherUserName': otherUserName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'partnerAvatar': partnerAvatar,
    };
  }
}
