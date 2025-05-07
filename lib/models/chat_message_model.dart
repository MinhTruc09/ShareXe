class ChatMessageModel {
  final int? id;
  final String? senderEmail;
  final String? receiverEmail;
  final String? senderName;
  final String content;
  final String roomId;
  final DateTime timestamp;
  final bool read;
  final String? status; // 'sending', 'sent', 'delivered', 'read', 'failed'

  ChatMessageModel({
    this.id,
    this.senderEmail,
    this.receiverEmail,
    this.senderName,
    required this.content,
    required this.roomId,
    required this.timestamp,
    required this.read,
    this.status,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      senderEmail: json['senderEmail'],
      receiverEmail: json['receiverEmail'],
      senderName: json['senderName'],
      content: json['content'],
      roomId: json['roomId'],
      timestamp: DateTime.parse(json['timestamp']),
      read: json['read'] ?? false,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'senderName': senderName,
      'content': content,
      'roomId': roomId,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'status': status,
    };
  }

  // Phương thức để tạo một bản sao với một số thuộc tính được cập nhật
  ChatMessageModel copyWith({
    int? id,
    String? senderEmail,
    String? receiverEmail,
    String? senderName,
    String? content,
    String? roomId,
    DateTime? timestamp,
    bool? read,
    String? status,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      roomId: roomId ?? this.roomId,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      status: status ?? this.status,
    );
  }
}
