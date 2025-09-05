// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final int statusCode;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 0,
      data: json['data'] != null ? fromJson(json['data']) : null,
    );
  }
}

// Passenger Profile DTO
class PassengerProfileDTO {
  final int id;
  final String? avatarUrl;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role;

  PassengerProfileDTO({
    required this.id,
    this.avatarUrl,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
  });

  factory PassengerProfileDTO.fromJson(Map<String, dynamic> json) {
    return PassengerProfileDTO(
      id: json['id'] ?? 0,
      avatarUrl: json['avatarUrl'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
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

// Keep backward compatibility
class Passenger {
  final bool success;
  final String message;
  final LoginData? data;

  Passenger({required this.success, required this.message, this.data});

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final int? id;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final String? token;

  LoginData({
    this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.role,
    this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      token: json['token'],
    );
  }
}
