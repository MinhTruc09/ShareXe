class Booking {
  final int id;
  final int rideId;
  final int passengerId;
  final int seatsBooked;
  final String passengerName;
  final String status;
  final String createdAt;

  Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.passengerName,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      rideId: json['rideId'],
      passengerId: json['passengerId'],
      seatsBooked: json['seatsBooked'],
      passengerName: json['passengerName'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'passengerId': passengerId,
      'seatsBooked': seatsBooked,
      'passengerName': passengerName,
      'status': status,
      'createdAt': createdAt,
    };
  }
} 