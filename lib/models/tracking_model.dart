class DriverLocation {
  final String rideId;
  final String driverEmail;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  DriverLocation({
    required this.rideId,
    required this.driverEmail,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      rideId: json['rideId'] ?? '',
      driverEmail: json['driverEmail'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      timestamp:
          json['timestamp'] != null
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

  DriverLocation copyWith({
    String? rideId,
    String? driverEmail,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) {
    return DriverLocation(
      rideId: rideId ?? this.rideId,
      driverEmail: driverEmail ?? this.driverEmail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class TrackingResponse {
  final String message;
  final int statusCode;
  final DriverLocation? data;
  final bool success;

  TrackingResponse({
    required this.message,
    required this.statusCode,
    required this.data,
    required this.success,
  });

  factory TrackingResponse.fromJson(Map<String, dynamic> json) {
    return TrackingResponse(
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 0,
      data: json['data'] != null ? DriverLocation.fromJson(json['data']) : null,
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'statusCode': statusCode,
      'data': data?.toJson(),
      'success': success,
    };
  }
}
