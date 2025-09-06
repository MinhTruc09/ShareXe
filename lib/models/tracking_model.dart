// Tracking model - mapping with API TrackingPayloadDTO schema
class TrackingModel {
  final String rideId;
  final String driverEmail;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  TrackingModel({
    required this.rideId,
    required this.driverEmail,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory TrackingModel.fromJson(Map<String, dynamic> json) {
    return TrackingModel(
      rideId: json['rideId'] ?? '',
      driverEmail: json['driverEmail'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'driverEmail': driverEmail,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  TrackingModel copyWith({
    String? rideId,
    String? driverEmail,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) {
    return TrackingModel(
      rideId: rideId ?? this.rideId,
      driverEmail: driverEmail ?? this.driverEmail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}