// VehicleDTO model for API mapping
class VehicleDTO {
  final String licensePlate;
  final String brand;
  final String model;
  final String color;
  final int numberOfSeats;
  final String? vehicleImageUrl;
  final String? licenseImageUrl;
  final String? licenseImagePublicId;
  final String? vehicleImagePublicId;

  VehicleDTO({
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
    required this.numberOfSeats,
    this.vehicleImageUrl,
    this.licenseImageUrl,
    this.licenseImagePublicId,
    this.vehicleImagePublicId,
  });

  factory VehicleDTO.fromJson(Map<String, dynamic> json) {
    return VehicleDTO(
      licensePlate: json['licensePlate'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      numberOfSeats: json['numberOfSeats'] ?? 0,
      vehicleImageUrl: json['vehicleImageUrl'],
      licenseImageUrl: json['licenseImageUrl'],
      licenseImagePublicId: json['licenseImagePublicId'],
      vehicleImagePublicId: json['vehicleImagePublicId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'licensePlate': licensePlate,
      'brand': brand,
      'model': model,
      'color': color,
      'numberOfSeats': numberOfSeats,
      'vehicleImageUrl': vehicleImageUrl,
      'licenseImageUrl': licenseImageUrl,
      'licenseImagePublicId': licenseImagePublicId,
      'vehicleImagePublicId': vehicleImagePublicId,
    };
  }
}
