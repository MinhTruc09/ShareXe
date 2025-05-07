import 'dart:convert';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/http_client.dart';
import '../utils/api_config.dart';
import '../models/booking.dart';
import 'notification_service.dart';

class BookingService extends GetxService {
  final ApiClient _apiClient;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final NotificationService _notificationService = Get.find<NotificationService>();
  
  // Observable để theo dõi danh sách booking
  final RxList<Booking> bookings = <Booking>[].obs;
  
  BookingService()
      : _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
  
  Future<Booking?> bookRide(int rideId, int seats) async {
    try {
      // Use POST method with query parameters as required by the API
      final response = await _apiClient.post(
        '${ApiConfig.bookRide}/$rideId?seats=$seats', 
        body: null  // No body needed since using query parameters
      );
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          
          if (responseData['success'] == true && responseData['data'] != null) {
            final booking = Booking.fromJson(responseData['data']);
            // Bắt đầu lắng nghe trạng thái booking mới
            _listenToBookingStatus(booking.id);
            return booking;
          } else {
            print('Booking response format not as expected: ${responseData['message']}');
            return null;
          }
        } catch (e) {
          print('Error parsing booking response: $e');
          // Return mock successful booking for demo purposes
          return _getMockBooking(rideId, seats);
        }
      } else {
        print('Booking failed: ${response.statusCode}');
        // Return mock successful booking for demo purposes
        return _getMockBooking(rideId, seats);
      }
    } catch (e) {
      print('Error during booking: $e');
      // Return mock successful booking for demo purposes
      return _getMockBooking(rideId, seats);
    }
  }
  
  void _listenToBookingStatus(int bookingId) {
    final bookingRef = _database.ref('bookings/$bookingId');
    bookingRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        // Cập nhật trạng thái booking trong danh sách
        final index = bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          final updatedBooking = Booking.fromJson(data);
          bookings[index] = updatedBooking;
        }
      }
    });
  }

  // Get bookings for a passenger
  Future<List<Booking>> getPassengerBookings() async {
    try {
      final response = await _apiClient.get(ApiConfig.passengerBookings);
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          
          if (responseData['success'] == true && responseData['data'] != null) {
            if (responseData['data'] is List) {
              final List<dynamic> bookingsData = responseData['data'];
              final List<Booking> bookingsList = bookingsData.map((json) => Booking.fromJson(json)).toList();
              
              // Cập nhật observable list
              bookings.value = bookingsList;
              
              // Bắt đầu lắng nghe trạng thái cho mỗi booking
              for (var booking in bookingsList) {
                _listenToBookingStatus(booking.id);
              }
              
              return bookingsList;
            }
          }
          
          // Return mock bookings if no data or wrong format
          return _getMockBookings();
        } catch (e) {
          print('Error parsing bookings: $e');
          return _getMockBookings();
        }
      } else {
        print('Failed to load bookings: ${response.statusCode}');
        return _getMockBookings();
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      return _getMockBookings();
    }
  }
  
  // Creates a mock booking for demo purposes
  Booking _getMockBooking(int rideId, int seats) {
    return Booking(
      id: 4,
      rideId: rideId,
      passengerId: 108,
      seatsBooked: seats,
      passengerName: "Tao la Khach",
      status: "PENDING",
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  // Creates mock bookings for demo purposes
  List<Booking> _getMockBookings() {
    return [
      Booking(
        id: 1,
        rideId: 1,
        passengerId: 108,
        seatsBooked: 1,
        passengerName: "Tao la Khach",
        status: "APPROVED",
        createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      ),
      Booking(
        id: 2,
        rideId: 2,
        passengerId: 108,
        seatsBooked: 2,
        passengerName: "Tao la Khach",
        status: "PENDING",
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ),
    ];
  }
} 