// Test file to verify model serialization round-trip
import 'booking.dart';

void testBookingDTORoundTrip() {
  // Sample JSON data matching API schema
  final sampleJson = {
    'id': 1,
    'rideId': 100,
    'seatsBooked': 2,
    'status': 'ACCEPTED',
    'createdAt': '2024-01-15T10:00:00Z',
    'totalPrice': 150.0,
    'departure': 'Hanoi',
    'destination': 'Ho Chi Minh City',
    'startTime': '2024-01-16T08:00:00Z',
    'pricePerSeat': 75.0,
    'rideStatus': 'ACTIVE',
    'totalSeats': 4,
    'availableSeats': 2,
    'driverId': 50,
    'driverName': 'John Doe',
    'driverPhone': '0123456789',
    'driverEmail': 'john@example.com',
    'driverAvatarUrl': 'https://example.com/avatar.jpg',
    'driverStatus': 'APPROVED',
    'vehicle': {
      'licensePlate': '29A-12345',
      'brand': 'Toyota',
      'model': 'Camry',
      'color': 'White',
      'numberOfSeats': 4,
      'vehicleImageUrl': 'https://example.com/vehicle.jpg',
      'licenseImageUrl': 'https://example.com/license.jpg',
      'licenseImagePublicId': 'lic123',
      'vehicleImagePublicId': 'veh123',
    },
    'passengerId': 200,
    'passengerName': 'Jane Smith',
    'passengerPhone': '0987654321',
    'passengerEmail': 'jane@example.com',
    'passengerAvatarUrl': 'https://example.com/passenger.jpg',
    'fellowPassengers': [
      {
        'id': 201,
        'name': 'Bob Wilson',
        'phone': '0111111111',
        'email': 'bob@example.com',
        'avatarUrl': 'https://example.com/bob.jpg',
        'status': 'ACCEPTED',
        'seatsBooked': 1,
      },
    ],
  };

  // Test parsing from JSON
  final bookingDTO = BookingDTO.fromJson(sampleJson);
  print('✅ Successfully parsed BookingDTO from JSON');

  // Test serialization back to JSON
  final jsonOutput = bookingDTO.toJson();
  print('✅ Successfully serialized BookingDTO to JSON');

  // Verify key fields
  assert(bookingDTO.id == 1);
  assert(bookingDTO.rideId == 100);
  assert(bookingDTO.seatsBooked == 2);
  assert(bookingDTO.status == 'ACCEPTED');
  assert(bookingDTO.totalPrice == 150.0);
  assert(bookingDTO.departure == 'Hanoi');
  assert(bookingDTO.destination == 'Ho Chi Minh City');
  assert(bookingDTO.driverName == 'John Doe');
  assert(bookingDTO.passengerName == 'Jane Smith');
  assert(bookingDTO.vehicle != null);
  assert(bookingDTO.vehicle!.licensePlate == '29A-12345');
  assert(bookingDTO.fellowPassengers.length == 1);
  assert(bookingDTO.fellowPassengers[0].name == 'Bob Wilson');
  print('✅ All key fields verified');

  // Test round-trip consistency
  final roundTripDTO = BookingDTO.fromJson(jsonOutput);
  assert(roundTripDTO.id == bookingDTO.id);
  assert(
    roundTripDTO.vehicle?.licensePlate == bookingDTO.vehicle?.licensePlate,
  );
  assert(
    roundTripDTO.fellowPassengers.length == bookingDTO.fellowPassengers.length,
  );
  print('✅ Round-trip serialization successful');

  print('🎉 All BookingDTO tests passed!');
}

void testPassengerInfoDTORoundTrip() {
  final sampleJson = {
    'id': 201,
    'name': 'Alice Johnson',
    'phone': '0222222222',
    'email': 'alice@example.com',
    'avatarUrl': 'https://example.com/alice.jpg',
    'status': 'PENDING',
    'seatsBooked': 1,
  };

  final passenger = PassengerInfoDTO.fromJson(sampleJson);
  final jsonOutput = passenger.toJson();
  final roundTrip = PassengerInfoDTO.fromJson(jsonOutput);

  assert(passenger.id == 201);
  assert(passenger.name == 'Alice Johnson');
  assert(passenger.status == 'PENDING');
  assert(roundTrip.id == passenger.id);

  print('🎉 PassengerInfoDTO round-trip test passed!');
}

void testVehicleDTORoundTrip() {
  final sampleJson = {
    'licensePlate': '30A-67890',
    'brand': 'Honda',
    'model': 'Civic',
    'color': 'Black',
    'numberOfSeats': 5,
    'vehicleImageUrl': 'https://example.com/honda.jpg',
    'licenseImageUrl': 'https://example.com/honda-license.jpg',
    'licenseImagePublicId': 'lic456',
    'vehicleImagePublicId': 'veh456',
  };

  final vehicle = VehicleDTO.fromJson(sampleJson);
  final jsonOutput = vehicle.toJson();
  final roundTrip = VehicleDTO.fromJson(jsonOutput);

  assert(vehicle.licensePlate == '30A-67890');
  assert(vehicle.brand == 'Honda');
  assert(vehicle.numberOfSeats == 5);
  assert(roundTrip.licensePlate == vehicle.licensePlate);

  print('🎉 VehicleDTO round-trip test passed!');
}

void main() {
  print('🧪 Starting model serialization tests...');
  testBookingDTORoundTrip();
  testPassengerInfoDTORoundTrip();
  testVehicleDTORoundTrip();
  print('✅ All tests completed successfully!');
}
