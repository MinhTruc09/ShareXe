class ChatMessageDTO {
  final String? token;
  final String? senderEmail;
  final String? receiverEmail;
  final String? senderName;
  final String? content;
  final String? roomId;
  final DateTime? timestamp;
  final bool? read;

  ChatMessageDTO({
    this.token,
    this.senderEmail,
    this.receiverEmail,
    this.senderName,
    this.content,
    this.roomId,
    this.timestamp,
    this.read,
  });

  factory ChatMessageDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageDTO(
      token: json['token'],
      senderEmail: json['senderEmail'],
      receiverEmail: json['receiverEmail'],
      senderName: json['senderName'],
      content: json['content'],
      roomId: json['roomId'],
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      read: json['read'],
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
    };
  }

  ChatMessageDTO copyWith({
    String? token,
    String? senderEmail,
    String? receiverEmail,
    String? senderName,
    String? content,
    String? roomId,
    DateTime? timestamp,
    bool? read,
  }) {
    return ChatMessageDTO(
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


class ApiResponseChatMessageDTO {
  final String message;
  final int statusCode;
  final ChatMessageDTO? data;
  final bool success;

  ApiResponseChatMessageDTO({
    required this.message,
    required this.statusCode,
    required this.data,
    required this.success,
  });

  factory ApiResponseChatMessageDTO.fromJson(Map<String, dynamic> json) {
    return ApiResponseChatMessageDTO(
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 0,
      data: json['data'] != null ? ChatMessageDTO.fromJson(json['data']) : null,
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'data': data?.toJson(),
      'success': success,
    };
  }
}

class ApiResponseListChatMessageDTO {
  final String message;
  final int statusCode;
  final List<ChatMessageDTO> data;
  final bool success;

  ApiResponseListChatMessageDTO({
    required this.message,
    required this.statusCode,
    required this.data,
    required this.success,
  });

  factory ApiResponseListChatMessageDTO.fromJson(Map<String, dynamic> json) {
    List<ChatMessageDTO> messages = [];
    if (json['data'] != null) {
      messages =
          (json['data'] as List)
              .map((messageJson) => ChatMessageDTO.fromJson(messageJson))
              .toList();
    }

    return ApiResponseListChatMessageDTO(
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 0,
      data: messages,
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'data': data.map((message) => message.toJson()).toList(),
      'success': success,
    };
  }
}

class ApiResponseChatRoomId {
  final String message;
  final int statusCode;
  final String? data;
  final bool success;

  ApiResponseChatRoomId({
    required this.message,
    required this.statusCode,
    required this.data,
    required this.success,
  });

  factory ApiResponseChatRoomId.fromJson(Map<String, dynamic> json) {
    return ApiResponseChatRoomId(
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 0,
      data: json['data'],
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'data': data,
      'success': success,
    };
  }
}

class ApiResponseListChatRoom {
  final String message;
  final int statusCode;
  final List<Map<String, dynamic>> data;
  final bool success;

  ApiResponseListChatRoom({
    required this.message,
    required this.statusCode,
    required this.data,
    required this.success,
  });

  factory ApiResponseListChatRoom.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rooms = [];
    if (json['data'] != null) {
      rooms =
          (json['data'] as List)
              .map((roomJson) => roomJson as Map<String, dynamic>)
              .toList();
    }

    return ApiResponseListChatRoom(
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 0,
      data: rooms,
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'data': data,
      'success': success,
    };
  }
}
