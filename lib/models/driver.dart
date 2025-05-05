import 'package:sharexe/models/registration_data.dart';

class Driver {
  final int? id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? licensePlate;
  final String? licenseNumber;
  final String? licenseType;
  final String? licenseExpiry;
  final String? vehicleType;
  final String? vehicleColor;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? avatarImage;
  final String? licenseImage;
  final String? vehicleImage;
  final bool? isActive;
  final String? status; // PENDING, APPROVED, REJECTED
  final String? token;

  Driver({
    this.id,
    this.fullName,
    this.email,
    this.phone,
    this.licensePlate,
    this.licenseNumber,
    this.licenseType,
    this.licenseExpiry,
    this.vehicleType,
    this.vehicleColor,
    this.vehicleModel,
    this.vehicleYear,
    this.avatarImage,
    this.licenseImage,
    this.vehicleImage,
    this.isActive,
    this.status,
    this.token,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      licensePlate: json['licensePlate'],
      licenseNumber: json['licenseNumber'],
      licenseType: json['licenseType'],
      licenseExpiry: json['licenseExpiry'],
      vehicleType: json['vehicleType'],
      vehicleColor: json['vehicleColor'],
      vehicleModel: json['vehicleModel'],
      vehicleYear: json['vehicleYear'],
      avatarImage: json['avatarImage'],
      licenseImage: json['licenseImage'],
      vehicleImage: json['vehicleImage'],
      isActive: json['isActive'],
      status: json['status'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'licensePlate': licensePlate,
      'licenseNumber': licenseNumber,
      'licenseType': licenseType,
      'licenseExpiry': licenseExpiry,
      'vehicleType': vehicleType,
      'vehicleColor': vehicleColor,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'avatarImage': avatarImage,
      'licenseImage': licenseImage,
      'vehicleImage': vehicleImage,
      'isActive': isActive,
      'status': status,
      'token': token,
    };
  }

  // Chuyển từ RegistrationData sang Driver
  static Driver fromRegistrationData(RegistrationData data) {
    return Driver(
      fullName: data.fullName,
      email: data.email,
      phone: data.phone,
      licensePlate: data.licensePlate,
      licenseImage: data.licenseImage,
      vehicleImage: data.vehicleImage,
      avatarImage: data.avatarImage,
      status: 'PENDING',
      isActive: false,
    );
  }
} 