class Ride {
  final int id;
  final int availableSeats;
  final String driverName;
  final String driverEmail;
  final String departure;
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
      
      return Ride(
        id: parseIntSafely(json['id'], 0),
        availableSeats: parseIntSafely(json['availableSeats'], 0),
        driverName: json['driverName'] ?? 'Unknown Driver',
        driverEmail: json['driverEmail'] ?? 'no-email@example.com',
        departure: json['departure'] ?? 'Unknown',
        destination: json['destination'] ?? 'Unknown',
        startTime: json['startTime'] ?? DateTime.now().toIso8601String(),
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
      'destination': destination,
      'startTime': startTime,
      'pricePerSeat': pricePerSeat,
      'totalSeat': totalSeat,
      'status': status,
    };
  }
} 