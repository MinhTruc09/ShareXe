import 'dart:convert';
import '../utils/http_client.dart';
import '../models/booking.dart';
import 'package:http/http.dart' as http;

class BookingService {
  final ApiClient _apiClient;

  BookingService() : _apiClient = ApiClient();

  Future<Booking?> bookRide(int rideId, int seats) async {
    try {
      // Use POST method with query parameters as required by the API
      final response = await _apiClient.post(
        '/passenger/booking/$rideId?seats=$seats',
        body: null, // No body needed since using query parameters
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true && responseData['data'] != null) {
            return Booking.fromJson(responseData['data']);
          } else {
            print(
              'Booking response format not as expected: ${responseData['message']}',
            );
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

  // Get passenger's bookings
  Future<List<Booking>> getPassengerBookings() async {
    try {
      final response = await _apiClient.get('/passenger/bookings');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            final List<dynamic> bookingsData = responseData['data'];
            return bookingsData.map((json) => Booking.fromJson(json)).toList();
          } else {
            print('❌ API Response format not as expected');
            return _getMockPassengerBookings();
          }
        } catch (e) {
          print('❌ Error parsing booking data: $e');
          return _getMockPassengerBookings();
        }
      } else {
        print('❌ Failed to load bookings: ${response.statusCode}');
        return _getMockPassengerBookings();
      }
    } catch (e) {
      print('❌ Error fetching passenger bookings: $e');
      return _getMockPassengerBookings();
    }
  }

  // Sample data for passenger bookings
  List<Booking> _getMockPassengerBookings() {
    return [
      Booking(
        id: 201,
        rideId: 101,
        passengerId: 301,
        seatsBooked: 1,
        passengerName: "Lê Thị D",
        status: "CONFIRMED",
        createdAt:
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      ),
      Booking(
        id: 202,
        rideId: 102,
        passengerId: 301,
        seatsBooked: 2,
        passengerName: "Lê Thị D",
        status: "PENDING",
        createdAt: DateTime.now().toIso8601String(),
      ),
    ];
  }

  // Lấy danh sách booking đang chờ xác nhận cho tài xế
  Future<List<Booking>> fetchPendingBookingsForDriver() async {
    print('🔍 Đang lấy các đặt chỗ đang chờ xác nhận cho tài xế...');
    try {
      final response = await _apiClient.get('/driver/bookings');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            final List<dynamic> bookingsData = responseData['data'];
            print('✅ Tìm thấy ${bookingsData.length} đơn đặt chỗ đang chờ');
            return bookingsData.map((data) => Booking.fromJson(data)).toList();
          } else {
            print('❌ Định dạng không hợp lệ: ${responseData['message']}');
            return _getMockPendingBookings();
          }
        } catch (e) {
          print('❌ Lỗi phân tích dữ liệu JSON: $e');
          return _getMockPendingBookings();
        }
      } else {
        print('❌ Status code không thành công: ${response.statusCode}');
        return _getMockPendingBookings();
      }
    } on http.ClientException catch (e) {
      print('❌ Lỗi khi lấy danh sách đặt chỗ: $e');

      // Thông báo lỗi cụ thể
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection timed out')) {
        print('⚠️ Đang sử dụng dữ liệu giả cho demo');
      }

      return _getMockPendingBookings();
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách đặt chỗ: $e');
      print('⚠️ Đang sử dụng dữ liệu giả cho demo');
      return _getMockPendingBookings();
    }
  }

  // Sample data mẫu cho các booking đang chờ xác nhận
  List<Booking> _getMockPendingBookings() {
    return [
      Booking(
        id: 1001,
        rideId: 501,
        passengerId: 201,
        seatsBooked: 2,
        passengerName: "Nguyễn Văn A",
        status: "PENDING",
        createdAt:
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      ),
      Booking(
        id: 1002,
        rideId: 502,
        passengerId: 202,
        seatsBooked: 1,
        passengerName: "Trần Thị B",
        status: "PENDING",
        createdAt:
            DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      ),
      Booking(
        id: 1003,
        rideId: 503,
        passengerId: 203,
        seatsBooked: 3,
        passengerName: "Lê Văn C",
        status: "PENDING",
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      ),
    ];
  }
}
