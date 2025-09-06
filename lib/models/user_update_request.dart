// User Update Request model - mapping with API UserUpdateRequestDTO schema
class UserUpdateRequest {
  final String phone;
  final String fullName;
  final String licensePlate;
  final String brand;
  final String model;
  final String color;
  final int numberOfSeats;
  final String? vehicleImageUrl;
  final String? licenseImageUrl;
  final String? avatarImageUrl;

  UserUpdateRequest({
    required this.phone,
    required this.fullName,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
    required this.numberOfSeats,
    this.vehicleImageUrl,
    this.licenseImageUrl,
    this.avatarImageUrl,
  });

  factory UserUpdateRequest.fromJson(Map<String, dynamic> json) {
    return UserUpdateRequest(
      phone: json['phone'] ?? '',
      fullName: json['fullName'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      numberOfSeats: json['numberOfSeats'] ?? 0,
      vehicleImageUrl: json['vehicleImageUrl'],
      licenseImageUrl: json['licenseImageUrl'],
      avatarImageUrl: json['avatarImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'fullName': fullName,
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'color': color,
      'numberOfSeats': numberOfSeats,
      'vehicleImageUrl': vehicleImageUrl,
      'licenseImageUrl': licenseImageUrl,
      'avatarImageUrl': avatarImageUrl,
    };
  }

  UserUpdateRequest copyWith({
    String? phone,
    String? fullName,
    String? licensePlate,
    String? brand,
    String? model,
    String? color,
    int? numberOfSeats,
    String? vehicleImageUrl,
    String? licenseImageUrl,
    String? avatarImageUrl,
  }) {
    return UserUpdateRequest(
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      licensePlate: licensePlate ?? this.licensePlate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      color: color ?? this.color,
      numberOfSeats: numberOfSeats ?? this.numberOfSeats,
      vehicleImageUrl: vehicleImageUrl ?? this.vehicleImageUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      avatarImageUrl: avatarImageUrl ?? this.avatarImageUrl,
    );
  }
}