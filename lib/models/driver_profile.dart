class DriverProfile {
  final int id;
  final String? avatarUrl;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String? vehicleImageUrl; // Optional for driver
  final String? licenseImageUrl; // Optional for driver
  final String? vehicleType;     // Optional for driver
  final String? licensePlate;    // Optional for driver

  DriverProfile({
    required this.id,
    this.avatarUrl,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.vehicleImageUrl,
    this.licenseImageUrl,
    this.vehicleType,
    this.licensePlate,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: json['id'] ?? 0,
      avatarUrl: json['avatarUrl'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      role: json['role'] ?? 'DRIVER',
      vehicleImageUrl: json['vehicleImageUrl'],
      licenseImageUrl: json['licenseImageUrl'],
      vehicleType: json['vehicleType'],
      licensePlate: json['licensePlate'],
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
      'vehicleImageUrl': vehicleImageUrl,
      'licenseImageUrl': licenseImageUrl,
      'vehicleType': vehicleType,
      'licensePlate': licensePlate,
    };
  }
} 