class ChatRoom {
  final String id;
  final String userId; // The other person's ID (for current user, this is who they're talking to)
  final String userName; // The other person's name
  final String userAvatar; // The other person's avatar URL
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String rideId; // Associated ride ID
  
  ChatRoom({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.rideId,
  });
  
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      userAvatar: json['userAvatar'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      rideId: json['rideId'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'rideId': rideId,
    };
  }
} 