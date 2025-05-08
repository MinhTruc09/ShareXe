class UserProfile {
  final int id;
  final String? avatarUrl;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;

  UserProfile({
    required this.id,
    this.avatarUrl,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      avatarUrl: json['avatarUrl'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatarUrl': avatarUrl,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
    };
  }
}

class ProfileResponse {
  final String message;
  final UserProfile data;
  final bool success;
  final bool isOffline;

  ProfileResponse({
    required this.message,
    required this.data,
    required this.success,
    this.isOffline = false,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      message: json['message'] ?? '',
      data: UserProfile.fromJson(json['data'] ?? {}),
      success: json['success'] ?? false,
      isOffline: json['isOffline'] ?? false,
    );
  }
}
