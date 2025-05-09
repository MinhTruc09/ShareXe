import 'dart:convert';
import '../utils/http_client.dart';
import '../models/booking.dart';
import '../models/ride.dart';

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

  // Get bookings for a passenger
  Future<List<Booking>> getPassengerBookings() async {
    try {
      print('🔍 Lấy danh sách booking cho hành khách');

      final response = await _apiClient.get(
        '/passenger/bookings',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> bookingsData = responseData['data'];
          return bookingsData.map((json) => Booking.fromJson(json)).toList();
        }
      }

      print('❌ Lỗi khi lấy danh sách booking: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Exception khi lấy danh sách booking: $e');
      return [];
    }
  }

  // Get driver's pending bookings
  Future<List<Booking>> getDriverPendingBookings() async {
    try {
      print('🔍 Lấy danh sách booking chờ duyệt cho tài xế');
      // Sử dụng chung endpoint với getDriverBookings
      final response = await _apiClient.get(
        '/driver/bookings',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);

          if (responseData['success'] == true && responseData['data'] != null) {
            if (responseData['data'] is List) {
              final List<dynamic> bookingsData = responseData['data'];
              final List<Booking> bookings = [];

              // Lấy thông tin chi tiết về chuyến đi cho mỗi booking
              for (var bookingJson in bookingsData) {
                // Tạo đối tượng Booking cơ bản
                final booking = Booking.fromJson(bookingJson);

                // Chỉ lấy các booking có trạng thái PENDING
                if (booking.status.toUpperCase() != 'PENDING') {
                  continue;
                }

                // Lấy thông tin chi tiết về chuyến đi
                try {
                  final rideResponse = await _apiClient.get(
                    '/rides/${booking.rideId}',
                    requireAuth: true,
                  );

                  if (rideResponse.statusCode == 200) {
                    final rideData = json.decode(rideResponse.body);
                    if (rideData['success'] == true &&
                        rideData['data'] != null) {
                      final ride = Ride.fromJson(rideData['data']);

                      // Cập nhật booking với thông tin chuyến đi
                      final updatedBooking = booking.copyWith(
                        departure: ride.departure,
                        destination: ride.destination,
                        startTime: ride.startTime,
                        pricePerSeat: ride.pricePerSeat,
                      );

                      bookings.add(updatedBooking);
                    } else {
                      bookings.add(booking);
                    }
                  } else {
                    bookings.add(booking);
                  }
                } catch (e) {
                  print(
                    '❌ Lỗi khi lấy thông tin chuyến đi cho booking #${booking.id}: $e',
                  );
                  bookings.add(booking);
                }
              }

              return bookings;
            }
          }

          print(
            '❌ Không tìm thấy dữ liệu booking hoặc dữ liệu không đúng định dạng',
          );
          return [];
        } catch (e) {
          print('Error parsing driver bookings: $e');
          return [];
        }
      } else {
        print('Failed to load driver bookings: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching driver bookings: $e');
      return [];
    }
  }

  // Lấy danh sách booking cho tài xế
  Future<List<Booking>> getDriverBookings() async {
    try {
      print('🔍 Lấy danh sách booking cho tài xế');

      final response = await _apiClient.get(
        '/driver/bookings',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> bookingsData = responseData['data'];
          final List<Booking> bookings = [];

          for (var bookingJson in bookingsData) {
            // Tạo đối tượng Booking cơ bản
            final booking = Booking.fromJson(bookingJson);

            // Lấy thông tin chi tiết về chuyến đi
            try {
              final rideResponse = await _apiClient.get(
                '/rides/${booking.rideId}',
                requireAuth: true,
              );

              if (rideResponse.statusCode == 200) {
                final rideData = json.decode(rideResponse.body);
                if (rideData['success'] == true && rideData['data'] != null) {
                  final ride = Ride.fromJson(rideData['data']);

                  // Cập nhật booking với thông tin chuyến đi
                  final updatedBooking = booking.copyWith(
                    departure: ride.departure,
                    destination: ride.destination,
                    startTime: ride.startTime,
                    pricePerSeat: ride.pricePerSeat,
                  );

                  bookings.add(updatedBooking);
                } else {
                  bookings.add(booking);
                }
              } else {
                bookings.add(booking);
              }
            } catch (e) {
              print(
                '❌ Lỗi khi lấy thông tin chuyến đi cho booking #${booking.id}: $e',
              );
              bookings.add(booking);
            }
          }

          return bookings;
        }
      }

      print('❌ Lỗi khi lấy danh sách booking: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Exception khi lấy danh sách booking: $e');
      return [];
    }
  }

  // Chấp nhận booking
  Future<bool> acceptBooking(int bookingId) async {
    try {
      print('✅ Chấp nhận booking #$bookingId');

      final response = await _apiClient.put(
        '/driver/accept/$bookingId',
        requireAuth: true,
      );

      print('📝 [Accept] Response code: ${response.statusCode}');
      print('📝 [Accept] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Chấp nhận booking thành công');
        return true;
      } else {
        print('❌ Lỗi khi chấp nhận booking: ${response.statusCode}');
        print('❌ Chi tiết lỗi: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception khi chấp nhận booking: $e');
      return false;
    }
  }

  // Từ chối booking
  Future<bool> rejectBooking(int bookingId) async {
    try {
      print('❌ Từ chối booking #$bookingId');

      final response = await _apiClient.put(
        '/driver/reject/$bookingId',
        requireAuth: true,
      );

      print('📝 Response code: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Từ chối booking thành công');
        return true;
      } else {
        print('❌ Lỗi khi từ chối booking: ${response.statusCode}');
        print('❌ Chi tiết lỗi: ${response.body}');

        // Kiểm tra lỗi xác thực
        if (response.statusCode == 401 || response.statusCode == 403) {
          print('🔒 Có vấn đề với quyền truy cập hoặc xác thực');
        }

        // Kiểm tra lỗi không tìm thấy
        if (response.statusCode == 404) {
          print('🔍 Không tìm thấy booking hoặc endpoint không tồn tại');
        }

        return false;
      }
    } catch (e) {
      print('❌ Exception khi từ chối booking: $e');
      return false;
    }
  }

  // Hoàn thành chuyến đi
  Future<bool> completeRide(int rideId) async {
    try {
      print('🏁 Hoàn thành chuyến đi #$rideId');

      final response = await _apiClient.put(
        '/driver/complete/$rideId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        print('✅ Đã đánh dấu chuyến đi hoàn thành');
        return true;
      } else {
        print('❌ Lỗi khi hoàn thành chuyến đi: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception khi hoàn thành chuyến đi: $e');
      return false;
    }
  }
}
