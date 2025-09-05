class UserUpdateRequestDTO {
  final String? phone;
  final String? fullName;
  final String? licensePlate;
  final String? brand;
  final String? model;
  final String? color;
  final int? numberOfSeats;
  final String? vehicleImageUrl;
  final String? licenseImageUrl;
  final String? avatarImageUrl;

  UserUpdateRequestDTO({
    this.phone,
    this.fullName,
    this.licensePlate,
    this.brand,
    this.model,
    this.color,
    this.numberOfSeats,
    this.vehicleImageUrl,
    this.licenseImageUrl,
    this.avatarImageUrl,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (phone != null) data['phone'] = phone;
    if (fullName != null) data['fullName'] = fullName;
    if (licensePlate != null) data['licensePlate'] = licensePlate;
    if (brand != null) data['brand'] = brand;
    if (model != null) data['model'] = model;
    if (color != null) data['color'] = color;
    if (numberOfSeats != null) data['numberOfSeats'] = numberOfSeats;
    if (vehicleImageUrl != null) data['vehicleImageUrl'] = vehicleImageUrl;
    if (licenseImageUrl != null) data['licenseImageUrl'] = licenseImageUrl;
    if (avatarImageUrl != null) data['avatarImageUrl'] = avatarImageUrl;

    return data;
  }

  factory UserUpdateRequestDTO.fromJson(Map<String, dynamic> json) {
    return UserUpdateRequestDTO(
      phone: json['phone'],
      fullName: json['fullName'],
      licensePlate: json['licensePlate'],
      brand: json['brand'],
      model: json['model'],
      color: json['color'],
      numberOfSeats: json['numberOfSeats'],
      vehicleImageUrl: json['vehicleImageUrl'],
      licenseImageUrl: json['licenseImageUrl'],
      avatarImageUrl: json['avatarImageUrl'],
    );
  }
}

class ChangePasswordRequest {
  final String oldPass;
  final String newPass;

  ChangePasswordRequest({required this.oldPass, required this.newPass});

  Map<String, dynamic> toJson() {
    return {'oldPass': oldPass, 'newPass': newPass};
  }

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) {
    return ChangePasswordRequest(
      oldPass: json['oldPass'],
      newPass: json['newPass'],
    );
  }
}
