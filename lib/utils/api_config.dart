class ApiConfig {
  // Base URL cho API
  static const String baseUrl = 'https://209b-2405-4803-c83c-6d40-8464-c5f5-c484-d512.ngrok-free.app/api';

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String passengerProfile = '/passenger/profile';
  static const String passengerBookings = '/passenger/bookings';
  static const String availableRides = '/ride/available';
  static const String bookRide = '/passenger/booking';
  static const String driverAccept = '/driver/accept';
  static const String driverCancel = '/driver/cancel';
  static const String passengerCancel = '/passenger/cancel';
  static const String passengerConfirm = '/passenger/confirm';
} 