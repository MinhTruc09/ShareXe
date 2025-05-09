import '../utils/app_config.dart';

class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String? avatarUrl;
  final String? licenseImageUrl; // Chỉ dành cho tài xế
  final String? vehicleImageUrl; // Chỉ dành cho tài xế
  final String? status; // Chỉ dành cho tài xế: PENDING, APPROVED, REJECTED

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.avatarUrl,
    this.licenseImageUrl,
    this.vehicleImageUrl,
    this.status,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final appConfig = AppConfig();

    // Hàm tiện ích để chuyển đổi URL hình ảnh từ localhost thành baseUrl
    String? convertImageUrl(String? url) {
      if (url == null) return null;
      return url.replaceFirst('http://localhost:8080', appConfig.apiBaseUrl);
    }

    return UserProfile(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      // Hỗ trợ cả phoneNumber và phone vì backend đang sử dụng cả hai tên trường
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      role: json['role'] ?? '',
      // Hỗ trợ cả avatarUrl và avatarImage
      avatarUrl: convertImageUrl(json['avatarUrl'] ?? json['avatarImage']),
      licenseImageUrl: convertImageUrl(json['licenseImageUrl']),
      vehicleImageUrl: convertImageUrl(json['vehicleImageUrl']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'avatarUrl': avatarUrl,
      'licenseImageUrl': licenseImageUrl,
      'vehicleImageUrl': vehicleImageUrl,
      'status': status,
    };
  }

  // Tạo bản sao của UserProfile với một số trường được cập nhật
  UserProfile copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    String? avatarUrl,
    String? licenseImageUrl,
    String? vehicleImageUrl,
    String? status,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      vehicleImageUrl: vehicleImageUrl ?? this.vehicleImageUrl,
      status: status ?? this.status,
    );
  }
}

class ProfileResponse {
  final String message;
  final UserProfile data;
  final bool success;

  ProfileResponse({
    required this.message,
    required this.data,
    required this.success,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      message: json['message'] ?? '',
      data: UserProfile.fromJson(json['data'] ?? {}),
      success: json['success'] ?? false,
    );
  }
}
