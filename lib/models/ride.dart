class Ride {
  final int id;
  final int availableSeats;
  final String driverName;
  final String driverEmail;
  final String? driverPhone;
  final String departure;
  final String destination;
  final String startTime;
  final double pricePerSeat;
  final int totalSeat;
  String status;
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
  final String? licensePlate;
  final String? vehicleType;
  final String? vehicleColor;
  final String? vehicleModel;
  final String? vehicleBrand;
  final double? driverRating;
  final int? driverRatingCount;
  final String? driverAvatar;

  Ride({
    required this.id,
    required this.availableSeats,
    required this.driverName,
    required this.driverEmail,
    this.driverPhone,
    required this.departure,
    required this.destination,
    required this.startTime,
    required this.pricePerSeat,
    required this.totalSeat,
    required this.status,
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
    this.licensePlate,
    this.vehicleType,
    this.vehicleColor,
    this.vehicleModel,
    this.vehicleBrand,
    this.driverRating,
    this.driverRatingCount,
    this.driverAvatar,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    try {
      // Handle numeric values that might come as strings
      double? parsePrice(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          return double.tryParse(value) ?? null;
        }
        return null;
      }

      // Handle integer values safely
      int parseIntSafely(dynamic value, int defaultValue) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          return int.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      return Ride(
        id: parseIntSafely(json['id'], 0),
        availableSeats: parseIntSafely(json['availableSeats'], 0),
        driverName: json['driverName'] ?? 'Unknown Driver',
        driverEmail: json['driverEmail'] ?? 'no-email@example.com',
        driverPhone: json['driverPhone'],
        departure: json['departure'] ?? 'Unknown',
        destination: json['destination'] ?? 'Unknown',
        startTime: json['startTime'] ?? DateTime.now().toIso8601String(),
        pricePerSeat: parsePrice(json['pricePerSeat']) ?? 0.0,
        totalSeat: parseIntSafely(json['totalSeat'], 0),
        status: json['status'] ?? 'ACTIVE',
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
        licensePlate: json['licensePlate'],
        vehicleType: json['vehicleType'],
        vehicleColor: json['vehicleColor'],
        vehicleModel: json['vehicleModel'],
        vehicleBrand: json['vehicleBrand'] ?? json['brand'],
        driverRating: parsePrice(json['driverRating']),
        driverRatingCount: parseIntSafely(json['driverRatingCount'], 0),
        driverAvatar: json['driverAvatar'] ?? json['avatarImage'],
      );
    } catch (e) {
      print('❌ Error parsing Ride data: $e');
      print('❌ JSON that caused error: $json');
      // Return a default ride instead of crashing
      return Ride(
        id: 0,
        availableSeats: 0,
        driverName: 'Error Parsing Data',
        driverEmail: 'error@example.com',
        driverPhone: null,
        departure: 'Unknown',
        destination: 'Unknown',
        startTime: DateTime.now().toIso8601String(),
        pricePerSeat: 0.0,
        totalSeat: 0,
        status: 'ERROR',
        startLat: 0.0,
        startLng: 0.0,
        startAddress: '',
        startWard: '',
        startDistrict: '',
        startProvince: '',
        endLat: 0.0,
        endLng: 0.0,
        endAddress: '',
        endWard: '',
        endDistrict: '',
        endProvince: '',
        licensePlate: null,
        vehicleType: null,
        vehicleColor: null,
        vehicleModel: null,
        vehicleBrand: null,
        driverRating: null,
        driverRatingCount: null,
        driverAvatar: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'availableSeats': availableSeats,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'driverPhone': driverPhone,
      'departure': departure,
      'destination': destination,
      'startTime': startTime,
      'pricePerSeat': pricePerSeat,
      'totalSeat': totalSeat,
      'status': status,
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
      'licensePlate': licensePlate,
      'vehicleType': vehicleType,
      'vehicleColor': vehicleColor,
      'vehicleModel': vehicleModel,
      'vehicleBrand': vehicleBrand,
      'driverRating': driverRating,
      'driverRatingCount': driverRatingCount,
      'driverAvatar': driverAvatar,
    };
  }
}
