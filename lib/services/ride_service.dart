import 'dart:convert';
import '../models/ride.dart';
import '../utils/http_client.dart';
import '../services/auth_manager.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

class RideService {
  final ApiClient _apiClient;
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();

  RideService() : _apiClient = ApiClient();

  // Get available rides
  Future<List<Ride>> getAvailableRides() async {
    print('🔍 Fetching available rides from API...');
    print('🔍 Starting to fetch available rides...');
    print('🌐 API URL: ${_appConfig.availableRidesEndpoint}');

    // Check token validity
    await _authManager.checkAndPrintTokenValidity();

    try {
      // Try using the API client first
      print('📡 Attempting API call through ApiClient...');
      final response = await _apiClient.get('/ride/available');
      print('📡 Response received - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(
          '📡 Response body preview: ${response.body.substring(0, min(200, response.body.length))}...',
        );

        // Check if the response is HTML
        if (response.headers['content-type']?.contains('text/html') == true ||
            response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          print('⚠️ Received HTML instead of JSON, trying direct API call');
          // Try direct API call if the response is HTML
          return await _tryDirectApiCall();
        }

        try {
          print('📝 Parsing JSON response...');
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('📡 Response data keys: ${responseData.keys.join(", ")}');

          if (responseData['success'] == true && responseData['data'] != null) {
            print('✅ Success flag found in response');
            // Check if data is a list or a single object
            if (responseData['data'] is List) {
              final List<dynamic> rideData = responseData['data'];
              print('📊 Data is a List with ${rideData.length} items');
              final rides =
                  rideData.map((json) => Ride.fromJson(json)).toList();
              print('✅ Successfully parsed ${rides.length} rides from API');
              return rides;
            } else if (responseData['data'] is Map) {
              // If it's a single object, create a list with one item
              print('📊 Data is a Map (single object)');
              final ride = Ride.fromJson(responseData['data']);
              print('✅ Successfully parsed single ride from API');
              return [ride];
            }
          }
          print('❌ Response format not as expected, trying direct API call');
          // Try direct HTTP call
          return await _tryDirectApiCall();
        } catch (e) {
          print('❌ Error parsing JSON response: $e');
          // Try direct HTTP call with token
          return await _tryDirectApiCall();
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print(
          '🔒 Authentication error: ${response.statusCode}. Token might be invalid or expired.',
        );
        // Try direct HTTP call with token
        return await _tryDirectApiCall();
      } else {
        print('❌ Failed to load rides: ${response.statusCode}');
        // Try direct HTTP call as fallback
        return await _tryDirectApiCall();
      }
    } catch (e) {
      print('❌ Error fetching rides: $e');
      // Try direct HTTP call as fallback
      return await _tryDirectApiCall();
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
      final response = await _apiClient.get('/ride/$rideId');

      if (response.statusCode == 200) {
        // Check if the response is HTML
        if (response.headers['content-type']?.contains('text/html') == true ||
            response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          print('❌ Received HTML instead of JSON for ride details');
          // Return null if API unavailable
          return null;
        }

        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            return Ride.fromJson(responseData['data']);
          } else {
            print(
              '❌ Ride details response not as expected: ${responseData['message'] ?? 'Unknown error'}',
            );
            return null;
          }
        } catch (e) {
          print('❌ Error parsing ride details: $e');
          return null;
        }
      } else {
        print('❌ Failed to load ride details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting ride details: $e');
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

  // Tạo chuyến đi mới (dành cho tài xế)
  Future<Map<String, dynamic>> createRide({
    required String departure,
    required String destination,
    required DateTime startTime,
    required double pricePerSeat,
    required int totalSeat,
  }) async {
    try {
      print('🚗 Tạo chuyến đi mới...');

      // Chuẩn bị dữ liệu chuyến đi
      final Map<String, dynamic> rideRequest = {
        'departure': departure,
        'destination': destination,
        'startTime': startTime.toIso8601String(),
        'pricePerSeat': pricePerSeat,
        'totalSeat': totalSeat,
      };

      print('📦 Request body: ${jsonEncode(rideRequest)}');

      // Gọi API tạo chuyến đi
      try {
        final response = await _apiClient.post('/ride', body: rideRequest);

        if (response.statusCode == 201 || response.statusCode == 200) {
          print('✅ Tạo chuyến đi thành công');
          return {'success': true, 'message': 'Tạo chuyến đi thành công'};
        } else {
          print('❌ Tạo chuyến đi thất bại: ${response.statusCode}');
          print('📄 Response: ${response.body}');
          return {
            'success': false,
            'message': 'Mã lỗi: ${response.statusCode}',
          };
        }
      } on http.ClientException catch (e) {
        print('❌ Lỗi kết nối khi tạo chuyến đi: $e');

        // Kiểm tra lỗi kết nối
        if (e.toString().contains('Connection refused') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection timed out')) {
          // Trả về thông báo lỗi kết nối thân thiện hơn
          return {
            'success': false,
            'message':
                'Không thể kết nối tới máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại sau.',
            'connectionError': true,
          };
        }

        return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
      }
    } catch (e) {
      print('❌ Lỗi khi tạo chuyến đi: $e');
      return {'success': false, 'message': 'Đã xảy ra lỗi: ${e.toString()}'};
    }
  }

  // Lấy danh sách các chuyến đi của tài xế hiện tại
  Future<List<Ride>> getDriverRides() async {
    try {
      print('🔍 Đang lấy danh sách chuyến đi của tài xế...');
      final response = await _apiClient.get('/driver/my-rides');

      print('📡 Response Status: ${response.statusCode}');
      if (response.headers.containsKey('content-type')) {
        print('📡 Content-Type: ${response.headers['content-type']}');
      }

      // Debug response body
      if (response.body.isNotEmpty) {
        print(
          '📡 Response Body: ${response.body.substring(0, min(500, response.body.length))}${response.body.length > 500 ? "..." : ""}',
        );
      }

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('✅ Đã nhận dữ liệu chuyến đi của tài xế');

          if (responseData['success'] == true && responseData['data'] != null) {
            if (responseData['data'] is List) {
              final List<dynamic> rideData = responseData['data'];
              print('📊 Số lượng chuyến đi: ${rideData.length}');
              return rideData.map((json) => Ride.fromJson(json)).toList();
            }
          }
          print(
            '❌ Định dạng phản hồi không như mong đợi, trả về danh sách trống',
          );
          return [];
        } catch (e) {
          print('❌ Lỗi phân tích dữ liệu chuyến đi: $e');
          return []; // Trả về danh sách trống thay vì dữ liệu mẫu
        }
      } else if (response.statusCode == 403) {
        print('❌ Lỗi quyền truy cập API (403)');
        return []; // Trả về danh sách trống
      } else {
        print('❌ Không thể lấy danh sách chuyến đi: ${response.statusCode}');
        return []; // Trả về danh sách trống
      }
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách chuyến đi: $e');
      return []; // Trả về danh sách trống
    }
  }
}
