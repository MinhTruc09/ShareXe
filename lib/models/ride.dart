// Ride model - mapping with API RideRequestDTO schema
class Ride {
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
  final String startTime;
  final double? pricePerSeat;
  final int totalSeat;
  String status;

  Ride({
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
    this.pricePerSeat,
    required this.totalSeat,
    required this.status,
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

      double parseDoubleSafely(dynamic value, double defaultValue) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          return double.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      // Handle startTime - could be DateTime string or already formatted
      String parseStartTime(dynamic value) {
        if (value == null) return DateTime.now().toIso8601String();
        if (value is String) {
          // Try to parse as DateTime and format
          try {
            return DateTime.parse(value).toIso8601String();
          } catch (e) {
            return value; // Return as is if parsing fails
          }
        }
        return DateTime.now().toIso8601String();
      }

      return Ride(
        id: parseIntSafely(json['id'], 0),
        availableSeats: parseIntSafely(json['availableSeats'], 0),
        driverName: json['driverName'] ?? 'Unknown Driver',
        driverEmail: json['driverEmail'] ?? 'no-email@example.com',
        departure: json['departure'] ?? 'Unknown',
        startLat: parseDoubleSafely(json['startLat'], 0.0),
        startLng: parseDoubleSafely(json['startLng'], 0.0),
        startAddress: json['startAddress'] ?? '',
        startWard: json['startWard'] ?? '',
        startDistrict: json['startDistrict'] ?? '',
        startProvince: json['startProvince'] ?? '',
        endLat: parseDoubleSafely(json['endLat'], 0.0),
        endLng: parseDoubleSafely(json['endLng'], 0.0),
        endAddress: json['endAddress'] ?? '',
        endWard: json['endWard'] ?? '',
        endDistrict: json['endDistrict'] ?? '',
        endProvince: json['endProvince'] ?? '',
        destination: json['destination'] ?? 'Unknown',
        startTime: parseStartTime(json['startTime']),
        pricePerSeat: parsePrice(json['pricePerSeat']),
        totalSeat: parseIntSafely(json['totalSeat'], 0),
        status: json['status'] ?? 'ACTIVE',
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
        departure: 'Unknown',
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
        destination: 'Unknown',
        startTime: DateTime.now().toIso8601String(),
        pricePerSeat: null,
        totalSeat: 0,
        status: 'ERROR',
      );
    }
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
      'startTime': startTime,
      'pricePerSeat': pricePerSeat,
      'totalSeat': totalSeat,
      'status': status,
    };
  }

  // Helper method to convert to API format for creating/updating rides
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'availableSeats': availableSeats,
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
      'startTime': startTime,
      'pricePerSeat': pricePerSeat,
      'totalSeat': totalSeat,
      'status': status,
    };
  }
}
