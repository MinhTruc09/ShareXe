class Booking {
  final int id;
  final int rideId;
  final int passengerId;
  final int seatsBooked;
  final String passengerName;
  final String status; // PENDING, ACCEPTED, REJECTED, COMPLETED
  final String createdAt;
  final String? passengerAvatar;
  final double? totalPrice;

  Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.passengerName,
    required this.status,
    required this.createdAt,
    this.passengerAvatar,
    this.totalPrice,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      rideId: json['rideId'],
      passengerId: json['passengerId'],
      seatsBooked: json['seatsBooked'],
      passengerName: json['passengerName'] ?? 'Hành khách',
      status: json['status'],
      createdAt: json['createdAt'],
      passengerAvatar: json['passengerAvatar'],
      totalPrice: json['totalPrice']?.toDouble(),
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
      'passengerAvatar': passengerAvatar,
      'totalPrice': totalPrice,
    };
  }

  Booking copyWith({
    int? id,
    int? rideId,
    int? passengerId,
    int? seatsBooked,
    String? passengerName,
    String? status,
    String? createdAt,
    String? passengerAvatar,
    double? totalPrice,
  }) {
    return Booking(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      passengerName: passengerName ?? this.passengerName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      passengerAvatar: passengerAvatar ?? this.passengerAvatar,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
