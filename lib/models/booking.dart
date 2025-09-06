// Booking and BookingDTO models - updated to match API schema
// PassengerInfoDTO for fellow passengers
class PassengerInfoDTO {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String status;
  final int seatsBooked;

  PassengerInfoDTO({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarUrl,
    required this.status,
    required this.seatsBooked,
  });

  factory PassengerInfoDTO.fromJson(Map<String, dynamic> json) {
    return PassengerInfoDTO(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      status: json['status'] ?? 'PENDING',
      seatsBooked: json['seatsBooked'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'avatarUrl': avatarUrl,
      'status': status,
      'seatsBooked': seatsBooked,
    };
  }
}

// VehicleDTO for vehicle information
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

class BookingDTO {
  final int id;
  final int rideId;
  final int seatsBooked;
  final String status;
  final DateTime createdAt;
  final double totalPrice;

  // Ride info
  final String departure;
  final String destination;
  final DateTime startTime;
  final double pricePerSeat;
  final String rideStatus;
  final int totalSeats;
  final int availableSeats;

  // Driver info
  final int driverId;
  final String driverName;
  final String driverPhone;
  final String driverEmail;
  final String? driverAvatarUrl;
  final String driverStatus;
  final VehicleDTO? vehicle;

  // Passenger info
  final int passengerId;
  final String passengerName;
  final String passengerPhone;
  final String passengerEmail;
  final String? passengerAvatarUrl;

  // Fellow passengers info
  final List<PassengerInfoDTO> fellowPassengers;

  BookingDTO({
    required this.id,
    required this.rideId,
    required this.seatsBooked,
    required this.status,
    required this.createdAt,
    required this.totalPrice,
    required this.departure,
    required this.destination,
    required this.startTime,
    required this.pricePerSeat,
    required this.rideStatus,
    required this.totalSeats,
    required this.availableSeats,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverEmail,
    this.driverAvatarUrl,
    required this.driverStatus,
    this.vehicle,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.passengerEmail,
    this.passengerAvatarUrl,
    this.fellowPassengers = const [],
  });

  factory BookingDTO.fromJson(Map<String, dynamic> json) {
    List<PassengerInfoDTO> fellowPassengers = [];
    if (json['fellowPassengers'] != null) {
      fellowPassengers =
          (json['fellowPassengers'] as List)
              .map((fellowJson) => PassengerInfoDTO.fromJson(fellowJson))
              .toList();
    }

    VehicleDTO? vehicle;
    if (json['vehicle'] != null) {
      vehicle = VehicleDTO.fromJson(json['vehicle']);
    }

    return BookingDTO(
      id: json['id'] ?? 0,
      rideId: json['rideId'] ?? 0,
      seatsBooked: json['seatsBooked'] ?? 0,
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      totalPrice: json['totalPrice']?.toDouble() ?? 0.0,
      departure: json['departure'] ?? '',
      destination: json['destination'] ?? '',
      startTime:
          json['startTime'] != null
              ? DateTime.parse(json['startTime'])
              : DateTime.now(),
      pricePerSeat: json['pricePerSeat']?.toDouble() ?? 0.0,
      rideStatus: json['rideStatus'] ?? '',
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      driverId: json['driverId'] ?? 0,
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'] ?? '',
      driverEmail: json['driverEmail'] ?? '',
      driverAvatarUrl: json['driverAvatarUrl'],
      driverStatus: json['driverStatus'] ?? '',
      vehicle: vehicle,
      passengerId: json['passengerId'] ?? 0,
      passengerName: json['passengerName'] ?? '',
      passengerPhone: json['passengerPhone'] ?? '',
      passengerEmail: json['passengerEmail'] ?? '',
      passengerAvatarUrl: json['passengerAvatarUrl'],
      fellowPassengers: fellowPassengers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'seatsBooked': seatsBooked,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'totalPrice': totalPrice,
      'departure': departure,
      'destination': destination,
      'startTime': startTime.toIso8601String(),
      'pricePerSeat': pricePerSeat,
      'rideStatus': rideStatus,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverEmail': driverEmail,
      'driverAvatarUrl': driverAvatarUrl,
      'driverStatus': driverStatus,
      'vehicle': vehicle?.toJson(),
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'passengerEmail': passengerEmail,
      'passengerAvatarUrl': passengerAvatarUrl,
      'fellowPassengers':
          fellowPassengers.map((fellow) => fellow.toJson()).toList(),
    };
  }

  // Backward compatibility with existing Booking model
  Booking toBooking() {
    return Booking(
      id: id,
      rideId: rideId,
      passengerId: passengerId,
      seatsBooked: seatsBooked,
      passengerName: passengerName,
      status: status,
      createdAt: createdAt.toIso8601String(),
      passengerAvatar: passengerAvatarUrl,
      totalPrice: totalPrice,
      departure: departure,
      destination: destination,
      startTime: startTime.toIso8601String(),
      pricePerSeat: pricePerSeat,
    );
  }
}

// Keep the original Booking class for backward compatibility
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
  final String? departure;
  final String? destination;
  final String? startTime;
  final double? pricePerSeat;

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
    this.departure,
    this.destination,
    this.startTime,
    this.pricePerSeat,
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
      departure: json['departure'],
      destination: json['destination'],
      startTime: json['startTime'],
      pricePerSeat: json['pricePerSeat']?.toDouble(),
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
      'departure': departure,
      'destination': destination,
      'startTime': startTime,
      'pricePerSeat': pricePerSeat,
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
    String? departure,
    String? destination,
    String? startTime,
    double? pricePerSeat,
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
      departure: departure ?? this.departure,
      destination: destination ?? this.destination,
      startTime: startTime ?? this.startTime,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
    );
  }
}
