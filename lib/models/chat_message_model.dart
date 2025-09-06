// Chat Message model - mapping with API ChatMessageDTO schema
class ChatMessageModel {
  final String? token;
  final String senderEmail;
  final String receiverEmail;
  final String senderName;
  final String content;
  final String roomId;
  final DateTime timestamp;
  final bool read;

  ChatMessageModel({
    this.token,
    required this.senderEmail,
    required this.receiverEmail,
    required this.senderName,
    required this.content,
    required this.roomId,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      token: json['token'],
      senderEmail: json['senderEmail'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      roomId: json['roomId'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      read: json['read'] ?? false,
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
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }

  ChatMessageModel copyWith({
    String? token,
    String? senderEmail,
    String? receiverEmail,
    String? senderName,
    String? content,
    String? roomId,
    DateTime? timestamp,
    bool? read,
  }) {
    return ChatMessageModel(
      token: token ?? this.token,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      roomId: roomId ?? this.roomId,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}
