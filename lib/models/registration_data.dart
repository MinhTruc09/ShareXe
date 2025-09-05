class RegistrationData {
  String email;
  String password;
  String fullName;
  String phone;
  String avatarImage;
  String? licenseImage;
  String? vehicleImage;
  String? licensePlate;
  String? licenseNumber;
  String? licenseType;
  String? licenseExpiry;
  String? vehicleType;
  String? vehicleColor;
  String? vehicleModel;
  String? vehicleYear;
  String? brand;
  String? model;
  String? color;
  int? numberOfSeats;

  RegistrationData({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    this.avatarImage = '',
    this.licenseImage,
    this.vehicleImage,
    this.licensePlate,
    this.licenseNumber,
    this.licenseType,
    this.licenseExpiry,
    this.vehicleType,
    this.vehicleColor,
    this.vehicleModel,
    this.vehicleYear,
    this.brand,
    this.model,
    this.color,
    this.numberOfSeats,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'avatarImage': avatarImage,
      'licenseImage': licenseImage,
      'vehicleImage': vehicleImage,
      'licensePlate': licensePlate,
      'licenseNumber': licenseNumber,
      'licenseType': licenseType,
      'licenseExpiry': licenseExpiry,
      'vehicleType': vehicleType,
      'vehicleColor': vehicleColor,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'brand': brand,
      'model': model,
      'color': color,
      'numberOfSeats': numberOfSeats,
    };
  }

  factory RegistrationData.fromJson(Map<String, dynamic> json) {
    return RegistrationData(
      email: json['email'],
      password: json['password'],
      fullName: json['fullName'],
      phone: json['phone'],
      avatarImage: json['avatarImage'] ?? '',
      licenseImage: json['licenseImage'],
      vehicleImage: json['vehicleImage'],
      licensePlate: json['licensePlate'],
      licenseNumber: json['licenseNumber'],
      licenseType: json['licenseType'],
      licenseExpiry: json['licenseExpiry'],
      vehicleType: json['vehicleType'],
      vehicleColor: json['vehicleColor'],
      vehicleModel: json['vehicleModel'],
      vehicleYear: json['vehicleYear'],
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
      numberOfSeats: json['numberOfSeats'],
    );
  }
}
