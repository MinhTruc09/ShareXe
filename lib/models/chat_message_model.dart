class ChatMessageModel {
  final String? senderEmail;
  final String? receiverEmail;
  final String? senderName;
  final String content;
  final String roomId;
  final DateTime timestamp;
  final bool read;
  
  ChatMessageModel({
    this.senderEmail,
    this.receiverEmail,
    this.senderName,
    required this.content,
    required this.roomId,
    required this.timestamp,
    required this.read,
  });
  
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      senderEmail: json['senderEmail'],
      receiverEmail: json['receiverEmail'],
      senderName: json['senderName'],
      content: json['content'],
      roomId: json['roomId'],
      timestamp: DateTime.parse(json['timestamp']),
      read: json['read'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'senderName': senderName,
      'content': content,
      'roomId': roomId,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
    };
  }
} 