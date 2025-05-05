
class Passenger {
  final bool success;
  final String message;
  final LoginData? data;

  Passenger({
    required this.success,
    required this.message,
    this.data,
  });

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
  final String? phone;
  final String? role;
  final String? token;

  LoginData({
    this.id,
    this.fullName,
    this.email,
    this.phone,
    this.role,
    this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'],
      token: json['token'],
    );
  }
}
