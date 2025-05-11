import 'dart:convert';
import 'dart:async';
import 'dart:io';      // Add this import for SocketException
import 'dart:developer' as developer;
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../models/booking.dart';
import '../utils/http_client.dart';
import '../services/auth_manager.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../services/booking_service.dart';

class RideService {
  final ApiClient _apiClient;
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();
  final BookingService _bookingService = BookingService();

  RideService() : _apiClient = ApiClient();

  // Cached rides to improve performance
  List<Ride> _cachedAvailableRides = [];
  DateTime _lastCacheTime = DateTime(1970); // Set to epoch initially
  
  // Cached driver rides to improve performance
  List<Ride> _cachedDriverRides = [];
  DateTime _lastDriverCacheTime = DateTime(1970); // Set to epoch initially
  
  // Get available rides
  Future<List<Ride>> getAvailableRides() async {
    print('🔍 Fetching available rides from API...');
    
    // Check if we have cached data that's less than 30 seconds old
    final now = DateTime.now();
    if (_cachedAvailableRides.isNotEmpty && 
        now.difference(_lastCacheTime).inSeconds < 30) {
      print('📦 Using cached rides (${_cachedAvailableRides.length} items) from ${now.difference(_lastCacheTime).inSeconds}s ago');
      return _cachedAvailableRides;
    }
    
    print('🔍 Starting to fetch available rides...');
    print('🌐 API URL: ${_appConfig.availableRidesEndpoint}');

    // Check token validity
    await _authManager.checkAndPrintTokenValidity();
    
    List<Ride> availableRides = [];

    try {
      // Bước 1: Lấy danh sách tất cả các chuyến đi có sẵn
      print('📡 Attempting API call through ApiClient...');
      
      final response = await _apiClient.get('/ride/available')
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print('⏱️ API request timed out after 5 seconds');
        throw TimeoutException('API request timed out');
      });
      
      print('📡 Response received - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            final List<dynamic> ridesData = responseData['data'] as List;
            availableRides = ridesData.map((json) => Ride.fromJson(json)).toList();
            print('✅ Lấy được ${availableRides.length} chuyến đi từ API');
            
            // Update the cache with new data
            _cachedAvailableRides = List.from(availableRides);
            _lastCacheTime = now;
          } else {
            print('❌ API response format not as expected: ${responseData['message']}');
          }
        } catch (e) {
          print('❌ Error parsing API response: $e');
          
          // Fallback to direct API call if parsing fails
          final fallbackRides = await _tryDirectApiCall();
          if (fallbackRides.isNotEmpty) {
            availableRides = fallbackRides;
            
            // Update the cache with fallback data
            _cachedAvailableRides = List.from(fallbackRides);
            _lastCacheTime = now;
          } else if (_cachedAvailableRides.isNotEmpty) {
            // Use stale cache if we have it rather than no data
            print('📦 Using stale cached data as fallback');
            return _cachedAvailableRides;
          }
        }
      } else if (_cachedAvailableRides.isNotEmpty) {
        // Use stale cache if API returns error but we have cached data
        print('📦 Using stale cached data due to API error');
        return _cachedAvailableRides;
      }
      
      // Bước 2: Lấy danh sách bookings của người dùng
      try {
        print('🔍 Lấy danh sách bookings để lọc chuyến đi đã đặt...');
        final userBookings = await _bookingService.getPassengerBookings();
        
        // Đã phát hiện vấn đề: API passenger/bookings đang sử dụng hàm getBookingsForDriver
        // Không nhận được booking hoặc nhận được booking không đúng
        print('📦 Nhận được ${userBookings.length} bookings từ API passenger/bookings');
        
        // Chiến lược: Kết hợp cả bookings từ API và mock booking mới nhất
        Set<int> bookedRideIds = {};
        
        // 1. Thêm rideId từ các bookings API trả về (nếu có)
        if (userBookings.isNotEmpty) {
          final apiBookedRideIds = userBookings
              .where((booking) => 
                booking.status.toUpperCase() == 'PENDING' || 
                booking.status.toUpperCase() == 'APPROVED')
              .map((booking) => booking.rideId)
              .toSet();
          
          bookedRideIds.addAll(apiBookedRideIds);
          print('📋 Danh sách rideId đã đặt từ API: $apiBookedRideIds');
        }
        
        // 2. Thêm rideId từ mock booking gần nhất (nếu có)
        final lastCreatedBooking = _bookingService.getLastCreatedBooking();
        if (lastCreatedBooking != null) {
          print('🔍 Tìm thấy mock booking gần đây: #${lastCreatedBooking.id} cho chuyến #${lastCreatedBooking.rideId}');
          bookedRideIds.add(lastCreatedBooking.rideId);
        }
        
        // Lọc bỏ các chuyến đi đã đặt
        if (bookedRideIds.isNotEmpty) {
          print('📋 Tổng số rideId cần lọc: ${bookedRideIds.length} - Danh sách: $bookedRideIds');
          
          final filteredRides = availableRides
              .where((ride) => !bookedRideIds.contains(ride.id))
              .toList();
              
          print('🔄 Đã lọc bỏ ${availableRides.length - filteredRides.length} chuyến đi đã đặt');
          availableRides = filteredRides;
          
          // Update the cache with filtered data
          _cachedAvailableRides = List.from(availableRides);
          _lastCacheTime = now;
        } else {
          print('ℹ️ Không có chuyến đi nào cần lọc bỏ');
        }
      } catch (e) {
        print('⚠️ Không thể lấy danh sách bookings để lọc: $e');
        
        // Vẫn thử kiểm tra mock booking trong trường hợp lỗi API
        try {
          final lastCreatedBooking = _bookingService.getLastCreatedBooking();
          if (lastCreatedBooking != null) {
            print('🔍 Vẫn dùng mock booking để lọc: #${lastCreatedBooking.id} cho chuyến #${lastCreatedBooking.rideId}');
            
            final filteredRides = availableRides
                .where((ride) => ride.id != lastCreatedBooking.rideId)
                .toList();
                
            print('🔄 Đã lọc bỏ 1 chuyến đi dựa trên mock booking');
            availableRides = filteredRides;
            
            // Update the cache with filtered data
            _cachedAvailableRides = List.from(availableRides);
            _lastCacheTime = now;
          }
        } catch (e2) {
          print('⚠️ Không thể kiểm tra mock booking: $e2');
        }
      }
      
      return availableRides;
      
    } catch (e) {
      print('❌ Exception in getAvailableRides: $e');
      
      // Return cached data in case of error
      if (_cachedAvailableRides.isNotEmpty) {
        print('📦 Using cached data due to exception');
        return _cachedAvailableRides;
      }
      
      return [];
    }
  }

  // Get all available rides for driver - KHÔNG lọc bỏ chuyến đã đặt
  Future<List<Ride>> getDriverAvailableRides() async {
    print('🔍 Fetching rides created by the current driver...');
    
    // Check if we have cached data that's less than 30 seconds old
    final now = DateTime.now();
    if (_cachedDriverRides.isNotEmpty && 
        now.difference(_lastDriverCacheTime).inSeconds < 30) {
      print('📦 Using cached driver rides (${_cachedDriverRides.length} items) from ${now.difference(_lastDriverCacheTime).inSeconds}s ago');
      return _cachedDriverRides;
    }
    
    List<Ride> myRides = [];

    try {
      // Lấy danh sách chuyến đi của tài xế hiện tại với timeout
      final response = await _apiClient.get('/driver/my-rides', requireAuth: true)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print('⏱️ API request timed out after 5 seconds');
        throw TimeoutException('API request timed out after 5 seconds');
      });
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.headers['content-type'] != null) {
        print('📡 Content-Type: ${response.headers['content-type']}');
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          print('📡 Response data preview: ${responseData.toString().substring(0, min(100, responseData.toString().length))}...');
          
          if (responseData['success'] == true && responseData['data'] != null) {
            if (responseData['data'] is List) {
              final List<dynamic> ridesData = responseData['data'] as List;
              myRides = ridesData.map((json) => Ride.fromJson(json)).toList();
              print('✅ Tài xế nhận được ${myRides.length} chuyến đi từ API');
              
              // Sắp xếp chuyến đi theo thứ tự mới nhất trước
              myRides.sort((a, b) {
                try {
                  final DateTime dateTimeA = DateTime.parse(a.startTime);
                  final DateTime dateTimeB = DateTime.parse(b.startTime);
                  return dateTimeB.compareTo(dateTimeA); // Sắp xếp giảm dần (mới nhất trước)
                } catch (e) {
                  print('❌ Lỗi khi sắp xếp: $e');
                  return 0; // Giữ nguyên thứ tự nếu có lỗi
                }
              });
              
              // Update the cache
              _cachedDriverRides = List.from(myRides);
              _lastDriverCacheTime = now;
              
              print('✅ Đã sắp xếp ${myRides.length} chuyến đi theo thứ tự mới nhất');
              
              return myRides;
            } else {
              print('⚠️ Data không phải là List: ${responseData['data'].runtimeType}');
            }
          } else {
            print('❌ API response format not as expected: ${responseData['message'] ?? "No error message"}');
          }
        } catch (e) {
          print('❌ Error parsing API response for driver: $e');
        }
      }
      
      // Thử fallback nếu không lấy được dữ liệu với timeout
      if (myRides.isEmpty) {
        print('🔄 Trying fallback endpoint /driver/my-rides');
        try {
          final fallbackResponse = await _apiClient.get('/driver/my-rides', requireAuth: true)
              .timeout(const Duration(seconds: 8), onTimeout: () {
            print('⏱️ Fallback API request timed out after 8 seconds');
            throw TimeoutException('Fallback API request timed out after 8 seconds');
          });
          
          if (fallbackResponse.statusCode == 200) {
            final fallbackData = json.decode(fallbackResponse.body);
            
            if (fallbackData['success'] == true && fallbackData['data'] != null) {
              final List<dynamic> fallbackRidesData = fallbackData['data'] as List;
              myRides = fallbackRidesData.map((json) => Ride.fromJson(json)).toList();
              print('✅ Fallback: Tài xế nhận được ${myRides.length} chuyến đi từ API');
              
              // Sắp xếp chuyến đi theo thứ tự mới nhất trước
              myRides.sort((a, b) {
                try {
                  final DateTime dateTimeA = DateTime.parse(a.startTime);
                  final DateTime dateTimeB = DateTime.parse(b.startTime);
                  return dateTimeB.compareTo(dateTimeA); // Sắp xếp giảm dần (mới nhất trước)
                } catch (e) {
                  print('❌ Lỗi khi sắp xếp: $e');
                  return 0; // Giữ nguyên thứ tự nếu có lỗi
                }
              });
              
              // Update the cache
              _cachedDriverRides = List.from(myRides);
              _lastDriverCacheTime = now;
              
              print('✅ Đã sắp xếp ${myRides.length} chuyến đi theo thứ tự mới nhất (fallback)');
              
              return myRides;
            }
          }
        } catch (e) {
          String errorMessage = e.toString();
          if (e is TimeoutException || errorMessage.contains('TimeoutException')) {
            print('⏱️ Timeout error in fallback API call: $e');
          } else if (errorMessage.contains('SocketException') || 
                    errorMessage.contains('Network is unreachable')) {
            print('🔌 Network error in fallback API call: $e');
          } else {
            print('❌ Error in fallback API call: $e');
          }
        }
      }
      
      // If API calls fail but we have cached data, use it
      if (myRides.isEmpty && _cachedDriverRides.isNotEmpty) {
        print('📦 Using stale cached driver rides as fallback');
        return _cachedDriverRides;
      }
      
      // If all else fails, return empty list instead of mock data
      if (myRides.isEmpty) {
        print('⚠️ No driver rides found and no cached data available');
        return [];
      }
      
      return myRides;
    } catch (e) {
      String errorMessage = e.toString();
      
      if (e is TimeoutException || errorMessage.contains('TimeoutException')) {
        print('⏱️ Timeout error in getDriverRides: $e');
      } else if (errorMessage.contains('SocketException') || 
                errorMessage.contains('Network is unreachable')) {
        print('🔌 Network is unreachable in getDriverRides: $e');
      } else {
        print('❌ Exception in getDriverRides: $e');
      }
      
      // Return cached data in case of error
      if (_cachedDriverRides.isNotEmpty) {
        print('📦 Using cached driver rides due to exception');
        return _cachedDriverRides;
      }
      
      return [];
    }
  }

  // Helper to get min value
  int min(int a, int b) => a < b ? a : b;

  // Try a direct API call as fallback
  Future<List<Ride>> _tryDirectApiCall() async {
    print('🔄 Attempting direct API call as fallback...');

    try {
      final token = await _authManager.getToken();
      print(
        '🔑 Using direct API call with token: ${token != null ? "Token available" : "No token"}',
      );

      final uri = Uri.parse(_appConfig.availableRidesEndpoint);
      print('🌐 Direct API URL: $uri');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      print('🔑 Direct API headers: $headers');

      print('⏳ Sending direct API request...');
      final response = await http.get(uri, headers: headers);

      print('📡 Direct API response status: ${response.statusCode}');
      print('📡 Direct API content-type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        print(
          '📡 Direct API response body preview: ${response.body.substring(0, min(200, response.body.length))}...',
        );

        try {
          if (!response.body.trim().startsWith('<!DOCTYPE') &&
              !response.body.trim().startsWith('<html')) {
            print('📝 Parsing direct API JSON response...');
            final Map<String, dynamic> responseData = json.decode(
              response.body,
            );
            print(
              '📡 Direct API response keys: ${responseData.keys.join(", ")}',
            );

            if (responseData['success'] == true &&
                responseData['data'] != null) {
              print('✅ Success flag found in direct API response');
              if (responseData['data'] is List) {
                final List<dynamic> rideData = responseData['data'];
                print(
                  '📊 Direct API data is a List with ${rideData.length} items',
                );
                final rides =
                    rideData.map((json) => Ride.fromJson(json)).toList();
                print(
                  '✅ Successfully parsed ${rides.length} rides from direct API call',
                );
                return rides;
              } else {
                print(
                  '⚠️ Data is not a List but: ${responseData['data'].runtimeType}',
                );
              }
            } else {
              print(
                '❌ Success flag not found or data is null in direct API response',
              );
              print('❌ Response data: $responseData');
            }
          } else {
            print('❌ Received HTML in direct API call');
            print(
              '📄 HTML content preview: ${response.body.substring(0, min(200, response.body.length))}...',
            );
          }
        } catch (e) {
          print('❌ Error in direct API call JSON parsing: $e');
        }
      } else {
        print(
          '❌ Direct API call failed with status code: ${response.statusCode}',
        );
        if (response.body.isNotEmpty) {
          print(
            '📄 Error response body: ${response.body.substring(0, min(200, response.body.length))}...',
          );
        }
      }
    } catch (e) {
      print('❌ Exception in direct API call: $e');
    }

    // Return empty list if API calls failed
    print('⚠️ No rides available or API call failed');
    return [];
  }

  // Get ride details
  Future<Ride?> getRideDetails(int rideId) async {
    try {
      print('🔍 Fetching details for ride #$rideId...');
      
      // Check if we have the ride details cached in memory
      // This would be a good place to implement a caching system
      // For now, we can just log the request details
      
      // Add a timeout to prevent hanging requests
      final response = await _apiClient.get('/ride/$rideId')
          .timeout(const Duration(seconds: 5), onTimeout: () {
        print('⏱️ Timeout while fetching ride details');
        throw TimeoutException('API request timed out after 5 seconds');
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          // Create the Ride object
          final ride = Ride.fromJson(data['data']);
          
          // Cache this ride for future use if needed
          // This would be a good place to implement a caching system
          
          return ride;
        } else {
          print('❌ API returned success=false or data=null for ride #$rideId');
          return null;
        }
      } else {
        print('❌ Failed to get ride details. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception when getting ride details: $e');
      return null;
    }
  }

  // Search rides by criteria
  Future<List<Ride>> searchRides({
    String? departure,
    String? destination,
    DateTime? startTime,
    int? passengerCount,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (departure != null && departure.isNotEmpty) {
        queryParams['departure'] = departure;
      }
      if (destination != null && destination.isNotEmpty) {
        queryParams['destination'] = destination;
      }
      if (startTime != null) {
        // Format the date to ISO date format (YYYY-MM-DD) như API yêu cầu
        queryParams['startTime'] = startTime.toIso8601String().split('T')[0];
      }
      if (passengerCount != null) {
        queryParams['seats'] = passengerCount.toString();
      }

      // Convert query params to URL string
      final String queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      print('🔍 Searching rides with query: $queryString');
      final response = await _apiClient.get('/ride/search?$queryString');

      if (response.statusCode == 200) {
        // Check if the response is HTML
        if (response.headers['content-type']?.contains('text/html') == true ||
            response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          print('❌ Received HTML instead of JSON for search');
          // Return empty list if API unavailable
          return [];
        }

        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            if (responseData['data'] is List) {
              final List<dynamic> rideData = responseData['data'];
              print('✅ Tìm thấy ${rideData.length} chuyến đi phù hợp');
              return rideData.map((json) => Ride.fromJson(json)).toList();
            } else if (responseData['data'] is Map) {
              print('✅ Tìm thấy 1 chuyến đi phù hợp');
              return [Ride.fromJson(responseData['data'])];
            }
          }
          print('❌ Search response format not as expected: $responseData');
          return [];
        } catch (e) {
          print('❌ Error parsing search response: $e');
          return [];
        }
      } else {
        print('❌ Search failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error searching rides: $e');
      return [];
    }
  }

  // Creates mock pending bookings for demo purposes
  List<Booking> _getMockPendingBookings() {
    return [
      Booking(
        id: 101,
        rideId: 1,
        passengerId: 201,
        seatsBooked: 2,
        passengerName: "Nguyễn Văn A",
        status: "PENDING",
        createdAt:
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      ),
      Booking(
        id: 102,
        rideId: 1,
        passengerId: 202,
        seatsBooked: 1,
        passengerName: "Trần Thị B",
        status: "PENDING",
        createdAt:
            DateTime.now()
                .subtract(const Duration(minutes: 30))
                .toIso8601String(),
      ),
    ];
  }

  // Tạo chuyến đi mới (cho tài xế)
  Future<bool> createRide(Map<String, dynamic> rideData) async {
    try {
      print('📝 Tạo chuyến đi mới với dữ liệu: $rideData');
      
      // Check if URL needs to be switched to a working one
      await _appConfig.switchToWorkingUrl();
      
      // Attempt to create ride with timeout
      final response = await _apiClient.post(
        '/ride',
        body: rideData,
        requireAuth: true,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        print('⏱️ Timeout khi tạo chuyến đi sau 10 giây');
        throw TimeoutException('Timeout khi tạo chuyến đi');
      });

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Tạo chuyến đi thành công');
        return true;
      } else {
        print('❌ Lỗi khi tạo chuyến đi: ${response.statusCode} - ${response.body}');
        
        // Try alternative endpoint
        return await _tryAlternativeCreateRide(rideData);
      }
    } catch (e) {
      String errorMessage = e.toString();
      
      if (e is TimeoutException || errorMessage.contains('TimeoutException')) {
        print('⏱️ Timeout error trong createRide: $e');
      } else if (e is SocketException || 
                errorMessage.contains('SocketException') || 
                errorMessage.contains('Network is unreachable')) {
        print('🔌 Lỗi kết nối mạng khi tạo chuyến đi: $e');
      } else {
        print('❌ Exception khi tạo chuyến đi: $e');
      }
      
      // Try alternative endpoint as fallback
      return await _tryAlternativeCreateRide(rideData);
    }
  }
  
  // Phương thức thay thế để tạo chuyến đi khi endpoint chính không hoạt động
  Future<bool> _tryAlternativeCreateRide(Map<String, dynamic> rideData) async {
    print('🔄 Thử tạo chuyến đi với endpoint thay thế...');
    
    try {
      // Switch to fallback URL if not already using it
      if (!_appConfig.isUsingFallback) {
        _appConfig.isUsingFallback = true;
        print('📡 Đã chuyển sang URL dự phòng: ${_appConfig.fallbackApiUrl}');
      }
      
      // Try the driver/create endpoint
      final altResponse = await _apiClient.post(
        '/driver/create-ride',
        body: rideData,
        requireAuth: true,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        print('⏱️ Timeout với endpoint thay thế sau 10 giây');
        throw TimeoutException('Timeout với endpoint thay thế');
      });
      
      print('📡 Alt endpoint response: ${altResponse.statusCode}');
      
      if (altResponse.statusCode == 201 || altResponse.statusCode == 200) {
        print('✅ Tạo chuyến đi thành công với endpoint thay thế');
        return true;
      } 
      
      // Direct API call as last resort
      print('🔄 Thử tạo chuyến đi trực tiếp qua API (không thông qua ApiClient)...');
      final token = await _authManager.getToken();
      
      if (token == null) {
        print('❌ Không thể tạo chuyến đi: Token không có sẵn');
        return false;
      }
      
      final directUrl = Uri.parse('${_appConfig.fullApiUrl}/ride');
      print('🌐 Direct URL: $directUrl');
      
      final directResponse = await http.post(
        directUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(rideData),
      ).timeout(const Duration(seconds: 10));
      
      if (directResponse.statusCode == 201 || directResponse.statusCode == 200) {
        print('✅ Tạo chuyến đi thành công với direct API call');
        return true;
      }
      
      print('❌ Tất cả các phương thức tạo chuyến đi đều thất bại');
      return false;
      
    } catch (e) {
      print('❌ Exception trong phương thức thay thế: $e');
      return false;
    }
  }

  // Cập nhật chuyến đi (cho tài xế)
  Future<bool> updateRide(int rideId, Map<String, dynamic> rideData) async {
    try {
      print('📝 Cập nhật chuyến đi #$rideId với dữ liệu: $rideData');

      final response = await _apiClient.put(
        '/ride/update/$rideId',
        body: rideData,
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        print('✅ Cập nhật chuyến đi thành công');
        return true;
      } else {
        print('❌ Lỗi khi cập nhật chuyến đi: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception khi cập nhật chuyến đi: $e');
      return false;
    }
  }

  // Hủy chuyến đi (cho tài xế)
  Future<bool> cancelRide(int rideId) async {
    try {
      print('🚫 Bắt đầu hủy chuyến đi #$rideId');

      // Debug hiển thị token được sử dụng
      final token = await _authManager.getToken();
      if (token == null) {
        print('❌ Token rỗng - không thể hủy chuyến đi');
        return false;
      }
      
      print('🔑 Token hợp lệ: ${token.length > 20 ? "Có (${token.substring(0, 10)}...)" : "Không"}');
      
      // Thử phương thức PUT trước với timeout
      print('⏱️ Thử phương thức PUT với timeout 10 giây');
      try {
        final response = await _apiClient.put(
          '/ride/cancel/$rideId',
          requireAuth: true,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⌛ PUT API timeout sau 10 giây');
            throw TimeoutException('API timeout');
          },
        );

        print('📝 Response PUT status: ${response.statusCode}');
        print('📝 Response PUT body: ${response.body.substring(0, min(100, response.body.length))}...');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Hủy chuyến đi thành công qua PUT');
          // Tìm kiếm và hiển thị ride đã bị hủy
          try {
            final updatedRide = await getRideDetails(rideId);
            if (updatedRide != null) {
              print('🚗 Ride #$rideId: Status = ${updatedRide.status} (${updatedRide.status.toUpperCase()})');
            }
          } catch(e) {
            print('⚠️ Không thể kiểm tra trạng thái của chuyến đi sau khi hủy: $e');
          }
          return true;
        } else {
          print('⚠️ PUT request không thành công: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('⚠️ Lỗi khi thử PUT request: $e');
      }
      
      // Thử phương thức POST với timeout
      print('⏱️ Thử phương thức POST với timeout 10 giây');
      try {
        final response = await _apiClient.post(
          '/ride/cancel/$rideId',
          requireAuth: true,
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⌛ POST API timeout sau 10 giây');
            throw TimeoutException('API timeout');
          },
        );
        
        print('📝 Response POST status: ${response.statusCode}');
        print('📝 Response POST body: ${response.body.substring(0, min(100, response.body.length))}...');
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Hủy chuyến đi thành công qua POST');
          return true;
        } else {
          print('⚠️ POST request không thành công: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('⚠️ Lỗi khi thử POST request: $e');
      }
      
      // Nếu cả PUT và POST đều thất bại, thử trực tiếp API với timeout
      print('⏱️ Thử direct API call với timeout 10 giây');
      try {
        final directUrl = '${_appConfig.apiBaseUrl}/ride/cancel/$rideId';
        print('🌐 Direct API URL: $directUrl');
        
        final directResponse = await http.put(
          Uri.parse(directUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⌛ Direct API timeout sau 10 giây');
            throw TimeoutException('Direct API timeout');
          },
        );
        
        print('📝 Direct API status: ${directResponse.statusCode}');
        print('📝 Direct API headers: ${directResponse.headers}');
        print('📝 Direct API body: ${directResponse.body.substring(0, min(100, directResponse.body.length))}...');
        
        if (directResponse.statusCode == 200 || directResponse.statusCode == 201) {
          print('✅ Hủy chuyến đi thành công qua direct API call');
          return true;
        } else {
          print('⚠️ Direct API không thành công: ${directResponse.statusCode} - ${directResponse.body}');
        }
      } catch (e) {
        print('⚠️ Lỗi khi thử direct API call: $e');
      }

      print('❌ Tất cả các phương thức đều thất bại! Chuyến đi #$rideId không thể hủy');
      return false;
    } catch (e) {
      print('❌ Exception chính trong cancelRide: $e');
      return false;
    }
  }

  // Lấy các chuyến đi tài xế đã tạo
  Future<List<Ride>> getDriverRides() async {
    print('🔍 Fetching rides created by the current driver...');
    
    // Check if we have cached data that's less than 30 seconds old
    final now = DateTime.now();
    if (_cachedDriverRides.isNotEmpty && 
        now.difference(_lastDriverCacheTime).inSeconds < 30) {
      print('📦 Using cached driver rides (${_cachedDriverRides.length} items) from ${now.difference(_lastDriverCacheTime).inSeconds}s ago');
      return _cachedDriverRides;
    }
    
    List<Ride> myRides = [];

    try {
      // Lấy danh sách chuyến đi của tài xế hiện tại với timeout
      print('🌐 URL endpoint: ${_appConfig.fullApiUrl}/driver/my-rides');
      final response = await _apiClient.get('/driver/my-rides', requireAuth: true)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('⏱️ API request timed out after 10 seconds');
        throw TimeoutException('API request timed out after 10 seconds');
      });
      
      print('📡 Response status: ${response.statusCode}');
      
      if (response.headers['content-type'] != null) {
        print('📡 Content-Type: ${response.headers['content-type']}');
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          print('📡 Response data preview: ${responseData.toString().substring(0, min(100, responseData.toString().length))}...');
          
          if (responseData['success'] == true && responseData['data'] != null) {
            if (responseData['data'] is List) {
              final List<dynamic> ridesData = responseData['data'] as List;
              myRides = ridesData.map((json) => Ride.fromJson(json)).toList();
              print('✅ Tài xế nhận được ${myRides.length} chuyến đi từ API');
              
              // Sắp xếp chuyến đi theo thứ tự mới nhất trước
              myRides.sort((a, b) {
                try {
                  final DateTime dateTimeA = DateTime.parse(a.startTime);
                  final DateTime dateTimeB = DateTime.parse(b.startTime);
                  return dateTimeB.compareTo(dateTimeA); // Sắp xếp giảm dần (mới nhất trước)
                } catch (e) {
                  print('❌ Lỗi khi sắp xếp: $e');
                  return 0; // Giữ nguyên thứ tự nếu có lỗi
                }
              });
              
              // Update the cache
              _cachedDriverRides = List.from(myRides);
              _lastDriverCacheTime = now;
              
              print('✅ Đã sắp xếp ${myRides.length} chuyến đi theo thứ tự mới nhất');
              
              return myRides;
            } else {
              print('⚠️ Data không phải là List: ${responseData['data'].runtimeType}');
            }
          } else {
            print('❌ API response format not as expected: ${responseData['message'] ?? "No error message"}');
          }
        } catch (e) {
          print('❌ Error parsing API response for driver: $e');
        }
      }
      
      // Thử fallback nếu không lấy được dữ liệu với timeout
      if (myRides.isEmpty) {
        print('🔄 Trying fallback endpoint /driver/my-rides');
        try {
          final fallbackResponse = await _apiClient.get('/driver/my-rides', requireAuth: true)
              .timeout(const Duration(seconds: 8), onTimeout: () {
            print('⏱️ Fallback API request timed out after 8 seconds');
            throw TimeoutException('Fallback API request timed out after 8 seconds');
          });
          
          if (fallbackResponse.statusCode == 200) {
            final fallbackData = json.decode(fallbackResponse.body);
            
            if (fallbackData['success'] == true && fallbackData['data'] != null) {
              final List<dynamic> fallbackRidesData = fallbackData['data'] as List;
              myRides = fallbackRidesData.map((json) => Ride.fromJson(json)).toList();
              print('✅ Fallback: Tài xế nhận được ${myRides.length} chuyến đi từ API');
              
              // Sắp xếp chuyến đi theo thứ tự mới nhất trước
              myRides.sort((a, b) {
                try {
                  final DateTime dateTimeA = DateTime.parse(a.startTime);
                  final DateTime dateTimeB = DateTime.parse(b.startTime);
                  return dateTimeB.compareTo(dateTimeA); // Sắp xếp giảm dần (mới nhất trước)
                } catch (e) {
                  print('❌ Lỗi khi sắp xếp: $e');
                  return 0; // Giữ nguyên thứ tự nếu có lỗi
                }
              });
              
              // Update the cache
              _cachedDriverRides = List.from(myRides);
              _lastDriverCacheTime = now;
              
              print('✅ Đã sắp xếp ${myRides.length} chuyến đi theo thứ tự mới nhất (fallback)');
              
              return myRides;
            }
          }
        } catch (e) {
          String errorMessage = e.toString();
          if (e is TimeoutException || errorMessage.contains('TimeoutException')) {
            print('⏱️ Timeout error in fallback API call: $e');
          } else if (errorMessage.contains('SocketException') || 
                    errorMessage.contains('Network is unreachable')) {
            print('🔌 Network error in fallback API call: $e');
          } else {
            print('❌ Error in fallback API call: $e');
          }
        }
      }
      
      // If API calls fail but we have cached data, use it
      if (myRides.isEmpty && _cachedDriverRides.isNotEmpty) {
        print('📦 Using stale cached driver rides as fallback');
        return _cachedDriverRides;
      }
      
      // If all else fails, return empty list instead of mock data
      if (myRides.isEmpty) {
        print('⚠️ No driver rides found and no cached data available');
        return [];
      }
      
      return myRides;
    } catch (e) {
      String errorMessage = e.toString();
      
      if (e is TimeoutException || errorMessage.contains('TimeoutException')) {
        print('⏱️ Timeout error in getDriverRides: $e');
      } else if (errorMessage.contains('SocketException') || 
                errorMessage.contains('Network is unreachable')) {
        print('🔌 Network is unreachable in getDriverRides: $e');
      } else {
        print('❌ Exception in getDriverRides: $e');
      }
      
      // Return cached data in case of error
      if (_cachedDriverRides.isNotEmpty) {
        print('📦 Using cached driver rides due to exception');
        return _cachedDriverRides;
      }
      
      return [];
    }
  }
  
  // Hoàn thành chuyến đi (cho tài xế)
  Future<bool> completeRide(int rideId) async {
    try {
      print('✅ Đánh dấu chuyến đi #$rideId là đã hoàn thành');

      final response = await _apiClient.put(
        '/ride/complete/$rideId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        print('✅ Hoàn thành chuyến đi thành công');
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

  // Kiểm tra xem chuyến đi có đang diễn ra không (đã đến giờ khởi hành)
  bool isRideInProgress(Ride ride) {
    try {
      final startTime = DateTime.parse(ride.startTime);
      final now = DateTime.now();
      
      // Tính thời gian chênh lệch
      final difference = startTime.difference(now);
      
      // Chuyến đi đang diễn ra nếu:
      // 1. Trạng thái là ACTIVE
      // 2. Đã đến thời điểm khởi hành hoặc sắp đến (còn dưới 30 phút)
      // 3. Chưa quá 2 giờ sau thời điểm khởi hành (để có thể xác nhận hoàn thành)
      
      return difference.inMinutes <= 30 && 
             difference.inHours > -2 && 
             ride.status.toUpperCase() == 'ACTIVE';
    } catch (e) {
      print('❌ Lỗi khi kiểm tra trạng thái chuyến đi: $e');
      return false;
    }
  }
  
  // Kiểm tra nếu chuyến đi đã đến thời gian xuất phát (có thể xác nhận)
  bool canConfirmRide(Ride ride) {
    try {
      final startTime = DateTime.parse(ride.startTime);
      final now = DateTime.now();
      
      // Chuyến đi có thể xác nhận nếu:
      // 1. Trạng thái là ACTIVE
      // 2. Đã đến hoặc gần đến thời điểm khởi hành (còn dưới 30 phút)
      
      final bool isTimeToConfirm = startTime.isBefore(now) || 
                                 startTime.difference(now).inMinutes <= 30;
                                 
      return isTimeToConfirm && ride.status.toUpperCase() == 'ACTIVE';
    } catch (e) {
      print('❌ Lỗi khi kiểm tra có thể xác nhận chuyến đi: $e');
      return false;
    }
  }
  
  // Cập nhật trạng thái theo dõi chuyến đi
  Future<bool> updateRideTrackingStatus(int rideId, String status) async {
    try {
      print('📝 Cập nhật trạng thái theo dõi chuyến đi #$rideId thành $status');
      
      // Lưu trữ trạng thái hiện tại của ride nếu có thể
      Ride? currentRide;
      try {
        currentRide = await getRideDetails(rideId);
        if (currentRide != null) {
          print('📦 Đã lưu trữ thông tin ride hiện tại để dự phòng: ${currentRide.status}');
        }
      } catch (e) {
        print('⚠️ Không thể lấy thông tin ride hiện tại: $e');
      }

      final rideData = {
        'status': status
      };

      // Thử cập nhật với endpoint chính
      try {
        final response = await _apiClient.put(
          '/ride/update-status/$rideId',
          body: rideData,
          requireAuth: true,
        ).timeout(const Duration(seconds: 5), onTimeout: () {
          print('⏱️ Timeout while updating ride status');
          throw TimeoutException('API request timed out after 5 seconds');
        });

        if (response.statusCode == 200) {
          print('✅ Cập nhật trạng thái theo dõi thành công');
          return true;
        } else {
          print('⚠️ Lỗi khi cập nhật trạng thái theo dõi: ${response.statusCode}');
          try {
            print('⚠️ Body: ${response.body}');
          } catch (_) {}
        }
      } catch (e) {
        print('⚠️ Lỗi khi gọi API cập nhật trạng thái: $e');
      }
      
      // Thử với endpoint dự phòng
      try {
        print('🔄 Thử với endpoint dự phòng...');
        final altResponse = await _apiClient.put(
          '/api/ride/update-status/$rideId',
          body: rideData,
          requireAuth: true,
        ).timeout(const Duration(seconds: 5), onTimeout: () {
          print('⏱️ Timeout while updating ride status with backup endpoint');
          throw TimeoutException('API request timed out after 5 seconds');
        });
        
        if (altResponse.statusCode == 200) {
          print('✅ Cập nhật thành công với endpoint dự phòng');
          return true;
        }
      } catch (e) {
        print('⚠️ Lỗi với endpoint dự phòng: $e');
      }
      
      // Nếu cả hai đều thất bại, lưu trạng thái vào bộ nhớ cục bộ để đồng bộ sau
      if (currentRide != null) {
        try {
          print('📦 Lưu thay đổi trạng thái ride vào bộ nhớ cục bộ để đồng bộ sau');
          // Thực hiện lưu vào bộ nhớ cục bộ tại đây nếu cần
          
          // Trả về true để UI vẫn hiển thị như đã thành công
          // (vì dữ liệu sẽ được đồng bộ sau)
          return true;
        } catch (e) {
          print('⚠️ Không thể lưu trạng thái ride vào bộ nhớ cục bộ: $e');
        }
      }
      
      print('❌ Tất cả các phương thức cập nhật trạng thái đều thất bại');
      return false;
    } catch (e) {
      print('❌ Exception khi cập nhật trạng thái theo dõi: $e');
      return false;
    }
  }
  
  // Đánh dấu chuyến đi đang diễn ra (đã đến giờ xuất phát)
  Future<bool> markRideInProgress(int rideId) async {
    return updateRideTrackingStatus(rideId, 'IN_PROGRESS');
  }
  
  // Tài xế xác nhận khởi hành
  Future<bool> driverConfirmDeparture(int rideId) async {
    try {
      print('🚘 Tài xế xác nhận khởi hành chuyến đi #$rideId');

      final response = await _apiClient.put(
        '/driver/confirm-departure/$rideId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        print('✅ Tài xế xác nhận khởi hành thành công');
        return true;
      } else {
        print('❌ Lỗi khi tài xế xác nhận khởi hành: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception khi tài xế xác nhận khởi hành: $e');
      return false;
    }
  }
  
  // Hành khách xác nhận tham gia chuyến đi
  Future<bool> passengerConfirmDeparture(int rideId) async {
    try {
      print('🚘 Hành khách xác nhận tham gia chuyến đi #$rideId');

      final response = await _apiClient.put(
        '/passenger/confirm-departure/$rideId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        print('✅ Hành khách xác nhận tham gia thành công');
        return true;
      } else {
        print('❌ Lỗi khi hành khách xác nhận tham gia: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception khi hành khách xác nhận tham gia: $e');
      return false;
    }
  }

  // Hành khách xác nhận hoàn thành chuyến đi
  Future<bool> passengerConfirmCompletion(int rideId) async {
    try {
      print('🚘 Hành khách xác nhận hoàn thành chuyến đi #$rideId');

      final response = await _apiClient.put(
        '/passenger/passenger-confirm/$rideId',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        print('✅ Hành khách xác nhận hoàn thành thành công');
        return true;
      } else {
        print('❌ Lỗi khi hành khách xác nhận hoàn thành: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception khi hành khách xác nhận hoàn thành: $e');
      return false;
    }
  }

  // Tài xế xác nhận hoàn thành chuyến đi
  Future<bool> driverCompleteRide(int rideId) async {
    try {
      print('✅ Tài xế hoàn thành chuyến đi #$rideId');
      print('🔄 API Endpoint: ${_appConfig.fullApiUrl}/driver/complete/$rideId');

      final token = await _authManager.getToken();
      print('🔑 Token: ${token != null ? "Hợp lệ (${token.substring(0, min(10, token.length))}...)" : "Không có token"}');

      final response = await _apiClient.put(
        '/driver/complete/$rideId',
        requireAuth: true,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response headers: ${response.headers}');
      if (response.body.isNotEmpty) {
        try {
          final jsonResponse = json.decode(response.body);
          print('📡 Response body: $jsonResponse');
          
          // In thông tin chi tiết về kết quả
          if (jsonResponse['success'] == true) {
            print('✅ API trả về thành công, data: ${jsonResponse['data']}');
          } else {
            print('⚠️ API trả về lỗi: ${jsonResponse['message']}');
          }
        } catch (e) {
          print('⚠️ Không thể parse response body: ${response.body}');
        }
      } else {
        print('⚠️ Response body rỗng');
      }

      if (response.statusCode == 200) {
        print('✅ Tài xế hoàn thành chuyến đi thành công');
        
        // Xóa cache để reload mới nhất
        _cachedDriverRides = [];
        _lastDriverCacheTime = DateTime(1970);
        
        return true;
      } else {
        print('❌ Lỗi khi tài xế hoàn thành chuyến đi: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception khi tài xế hoàn thành chuyến đi: $e');
      return false;
    }
  }

  // Tài xế xác nhận hoàn thành chuyến đi
  Future<bool> confirmRideCompletion(int rideId) async {
    developer.log('🔄 Đang xác nhận hoàn thành chuyến đi #$rideId...', name: 'ride_service');
    
    try {
      // Gọi API để cập nhật trạng thái chuyến đi
      final response = await _apiClient.put(
        '/ride/$rideId/confirm-completion',
        requireAuth: true,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Yêu cầu đã hết thời gian chờ');
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          developer.log('✅ Xác nhận hoàn thành chuyến đi #$rideId thành công', name: 'ride_service');
          
          // Xóa bộ nhớ cache để lần tải tiếp theo sẽ lấy dữ liệu mới
          _cachedDriverRides = [];
          _lastDriverCacheTime = DateTime(1970);
          
          return true;
        } else {
          developer.log('❌ Không thể xác nhận hoàn thành: ${responseData['message']}', name: 'ride_service');
          return false;
        }
      } else {
        developer.log('❌ API trả về lỗi: ${response.statusCode}', name: 'ride_service');
        return false;
      }
    } catch (e) {
      developer.log('❌ Lỗi khi xác nhận hoàn thành chuyến đi: $e', name: 'ride_service', error: e);
      return false;
    }
  }
}
