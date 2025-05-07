class NotificationModel {
  final int id;
  final String userEmail;
  final String title;
  final String content;
  final String type;
  final int referenceId;
  final bool read;
  final DateTime createdAt;
  
  NotificationModel({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.content,
    required this.type,
    required this.referenceId,
    required this.read,
    required this.createdAt,
  });
  
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userEmail: json['userEmail'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      referenceId: json['referenceId'],
      read: json['read'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'title': title,
      'content': content,
      'type': type,
      'referenceId': referenceId,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 