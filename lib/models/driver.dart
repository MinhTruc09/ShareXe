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
  final String? brand;
  final String? model;
  final String? color;
  final int? numberOfSeats;
  final String? vehicleImageUrl;
  final String? licenseImageUrl;
  final String? address;
  final String? city;
  final String? district;
  final String? ward;

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
    this.brand,
    this.model,
    this.color,
    this.numberOfSeats,
    this.vehicleImageUrl,
    this.licenseImageUrl,
    this.address,
    this.city,
    this.district,
    this.ward,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double values
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    // Helper function to safely parse int values
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

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
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
      numberOfSeats: parseInt(json['numberOfSeats']),
      vehicleImageUrl: json['vehicleImageUrl'],
      licenseImageUrl: json['licenseImageUrl'],
      address: json['address'],
      city: json['city'],
      district: json['district'],
      ward: json['ward'],
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
      'brand': brand,
      'model': model,
      'color': color,
      'numberOfSeats': numberOfSeats,
      'vehicleImageUrl': vehicleImageUrl,
      'licenseImageUrl': licenseImageUrl,
      'address': address,
      'city': city,
      'district': district,
      'ward': ward,
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
      address: null,
      city: null,
      district: null,
      ward: null,
    );
  }
}
