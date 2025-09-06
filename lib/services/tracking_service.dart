import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/tracking_model.dart';
import '../utils/app_config.dart';
import 'auth_manager.dart';

class TrackingService {
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();

  /// Send driver location for tracking
  Future<TrackingResponse> sendDriverLocation({
    required String rideId,
    required String driverEmail,
    required double latitude,
    required double longitude,
    DateTime? timestamp,
  }) async {
    try {
      final token = await _authManager.getToken();
      if (token == null) {
        return TrackingResponse(
          message: 'Chưa đăng nhập',
          statusCode: 401,
          data: null,
          success: false,
        );
      }

      final endpoint = _appConfig.getEndpoint('tracking/test/$rideId');
      print('Sending driver location to: $endpoint');

      final locationData = DriverLocation(
        rideId: rideId,
        driverEmail: driverEmail,
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp ?? DateTime.now(),
      );

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(locationData.toJson()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Kết nối máy chủ quá hạn. Vui lòng thử lại sau.');
            },
          );

      print('Tracking response status: ${response.statusCode}');
      print('Tracking response body: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        return TrackingResponse(
          message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: response.statusCode,
          data: null,
          success: false,
        );
      }

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          return TrackingResponse.fromJson(responseData);
        } catch (parseError) {
          print('Error parsing tracking response: $parseError');
          return TrackingResponse(
            message: 'Gửi vị trí thành công',
            statusCode: 200,
            data: locationData,
            success: true,
          );
        }
      } else {
        try {
          final responseData = json.decode(response.body);
          return TrackingResponse(
            message: responseData['message'] ?? 'Lỗi không xác định',
            statusCode: response.statusCode,
            data: null,
            success: false,
          );
        } catch (parseError) {
          return TrackingResponse(
            message: 'Lỗi khi gửi vị trí: ${response.statusCode}',
            statusCode: response.statusCode,
            data: null,
            success: false,
          );
        }
      }
    } on SocketException catch (_) {
      return TrackingResponse(
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        data: null,
        success: false,
      );
    } catch (e) {
      return TrackingResponse(
        message: 'Lỗi: ${e.toString()}',
        statusCode: 0,
        data: null,
        success: false,
      );
    }
  }

  /// Send current location for a specific ride
  Future<bool> updateDriverLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final userRole = await _authManager.getUserRole();
      final userEmail = await _authManager.getUserEmail();

      if (userRole?.toUpperCase() != 'DRIVER' || userEmail == null) {
        print('Only drivers can send location updates');
        return false;
      }

      final result = await sendDriverLocation(
        rideId: rideId,
        driverEmail: userEmail,
        latitude: latitude,
        longitude: longitude,
      );

      return result.success;
    } catch (e) {
      print('Error updating driver location: $e');
      return false;
    }
  }
}
