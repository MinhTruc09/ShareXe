import 'package:sharexe/models/registration_data.dart';

// Driver Profile DTO - matches passenger profile structure
class DriverProfileDTO {
  final int id;
  final String? avatarUrl;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role;

  DriverProfileDTO({
    required this.id,
    this.avatarUrl,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
  });

  factory DriverProfileDTO.fromJson(Map<String, dynamic> json) {
    return DriverProfileDTO(
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

// Driver Ride DTO for /api/driver/my-rides
class DriverRideDTO {
  final int id;
  final int availableSeats;
  final String driverName;
  final String driverEmail;
  final String departure;
  final double startLat;
  final double startLng;
  final String startAddress;
  final String startWard;
  final String startDistrict;
  final String startProvince;
  final double endLat;
  final double endLng;
  final String endAddress;
  final String endWard;
  final String endDistrict;
  final String endProvince;
  final String destination;
  final DateTime startTime;
  final double pricePerSeat;
  final int totalSeat;
  final String status;

  DriverRideDTO({
    required this.id,
    required this.availableSeats,
    required this.driverName,
    required this.driverEmail,
    required this.departure,
    required this.startLat,
    required this.startLng,
    required this.startAddress,
    required this.startWard,
    required this.startDistrict,
    required this.startProvince,
    required this.endLat,
    required this.endLng,
    required this.endAddress,
    required this.endWard,
    required this.endDistrict,
    required this.endProvince,
    required this.destination,
    required this.startTime,
    required this.pricePerSeat,
    required this.totalSeat,
    required this.status,
  });

  factory DriverRideDTO.fromJson(Map<String, dynamic> json) {
    return DriverRideDTO(
      id: json['id'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      driverName: json['driverName'] ?? '',
      driverEmail: json['driverEmail'] ?? '',
      departure: json['departure'] ?? '',
      startLat: json['startLat']?.toDouble() ?? 0.0,
      startLng: json['startLng']?.toDouble() ?? 0.0,
      startAddress: json['startAddress'] ?? '',
      startWard: json['startWard'] ?? '',
      startDistrict: json['startDistrict'] ?? '',
      startProvince: json['startProvince'] ?? '',
      endLat: json['endLat']?.toDouble() ?? 0.0,
      endLng: json['endLng']?.toDouble() ?? 0.0,
      endAddress: json['endAddress'] ?? '',
      endWard: json['endWard'] ?? '',
      endDistrict: json['endDistrict'] ?? '',
      endProvince: json['endProvince'] ?? '',
      destination: json['destination'] ?? '',
      startTime: DateTime.parse(
        json['startTime'] ?? DateTime.now().toIso8601String(),
      ),
      pricePerSeat: json['pricePerSeat']?.toDouble() ?? 0.0,
      totalSeat: json['totalSeat'] ?? 0,
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'availableSeats': availableSeats,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'departure': departure,
      'startLat': startLat,
      'startLng': startLng,
      'startAddress': startAddress,
      'startWard': startWard,
      'startDistrict': startDistrict,
      'startProvince': startProvince,
      'endLat': endLat,
      'endLng': endLng,
      'endAddress': endAddress,
      'endWard': endWard,
      'endDistrict': endDistrict,
      'endProvince': endProvince,
      'destination': destination,
      'startTime': startTime.toIso8601String(),
      'pricePerSeat': pricePerSeat,
      'totalSeat': totalSeat,
      'status': status,
    };
  }
}

// Keep the original Driver class for backward compatibility
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
  final int? numberOfSeats;

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
    this.numberOfSeats,
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
      vehicleType: data.brand,
      vehicleModel: data.model,
      vehicleColor: data.color,
      numberOfSeats: data.numberOfSeats,
      status: 'PENDING',
      isActive: false,
    );
  }
}
