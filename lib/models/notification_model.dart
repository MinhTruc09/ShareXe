// Notification model - mapping with API Notification schema
class NotificationModel {
  final int id;
  final String userEmail;
  final String title;
  final String content;
  final String type;
  final int referenceId;
  final DateTime createdAt;
  final bool read;

  NotificationModel({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.content,
    required this.type,
    required this.referenceId,
    required this.createdAt,
    required this.read,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userEmail: json['userEmail'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? '',
      referenceId: json['referenceId'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      read: json['read'] ?? false,
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
      'createdAt': createdAt.toIso8601String(),
      'read': read,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? userEmail,
    String? title,
    String? content,
    String? type,
    int? referenceId,
    DateTime? createdAt,
    bool? read,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      read: read ?? this.read,
    );
  }
}