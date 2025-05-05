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
  });
}