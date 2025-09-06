import '../utils/app_config.dart';

class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String? avatarUrl;
  // Driver only fields from DriverDTO
  final String? status; // PENDING, APPROVED, REJECTED
  final String? licensePlate;
  final String? brand;
  final String? model;
  final String? color;
  final int? numberOfSeats;
  final String? vehicleImageUrl;
  final String? licenseImageUrl;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.avatarUrl,
    this.status,
    this.licensePlate,
    this.brand,
    this.model,
    this.color,
    this.numberOfSeats,
    this.vehicleImageUrl,
    this.licenseImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final appConfig = AppConfig();

    print('DEBUG: UserProfile.fromJson - Raw JSON: $json');

    // Hàm tiện ích để chuyển đổi URL hình ảnh từ localhost thành baseUrl
    String? convertImageUrl(String? url) {
      print('DEBUG: Converting URL: $url');
      if (url == null) return null;

      String convertedUrl = url.replaceFirst(
        'http://localhost:8080',
        appConfig.apiBaseUrl,
      );
      print('DEBUG: Converted URL: $convertedUrl');
      return convertedUrl;
    }

    // Kiểm tra các field liên quan đến avatar
    print('DEBUG: avatarUrl field: ${json['avatarUrl']}');
    print('DEBUG: avatarImage field: ${json['avatarImage']}');

    // Giá trị cuối cùng của avatarUrl
    String? finalAvatarUrl = convertImageUrl(
      json['avatarUrl'] ?? json['avatarImage'],
    );
    print('DEBUG: Final avatarUrl after conversion: $finalAvatarUrl');

    return UserProfile(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      // Hỗ trợ cả phoneNumber và phone vì backend đang sử dụng cả hai tên trường
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      role: json['role'] ?? '',
      // Hỗ trợ cả avatarUrl và avatarImage
      avatarUrl: finalAvatarUrl,
      status: json['status'],
      licensePlate: json['licensePlate'],
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
      numberOfSeats: json['numberOfSeats'],
      vehicleImageUrl: convertImageUrl(json['vehicleImageUrl']),
      licenseImageUrl: convertImageUrl(json['licenseImageUrl']),
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
      'status': status,
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'color': color,
      'numberOfSeats': numberOfSeats,
      'vehicleImageUrl': vehicleImageUrl,
      'licenseImageUrl': licenseImageUrl,
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
    String? status,
    String? licensePlate,
    String? brand,
    String? model,
    String? color,
    int? numberOfSeats,
    String? vehicleImageUrl,
    String? licenseImageUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      licensePlate: licensePlate ?? this.licensePlate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      numberOfSeats: numberOfSeats ?? this.numberOfSeats,
      vehicleImageUrl: vehicleImageUrl ?? this.vehicleImageUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
    );
  }
}

class ProfileResponse {
  final String message;
  final UserProfile? data;
  final bool success;

  ProfileResponse({
    required this.message,
    required this.data,
    required this.success,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final userData = json['data'];

    return ProfileResponse(
      message: json['message'] ?? '',
      data: userData != null ? UserProfile.fromJson(userData) : null,
      success: json['success'] ?? false,
    );
  }
}
