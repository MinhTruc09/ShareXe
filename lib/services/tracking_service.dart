import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import 'auth_manager.dart';
import 'websocket_service.dart';

// DriverLocation model for tracking
class DriverLocation {
  final String rideId;
  final String driverEmail;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  DriverLocation({
    required this.rideId,
    required this.driverEmail,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'driverEmail': driverEmail,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// TrackingResponse model
class TrackingResponse {
  final String message;
  final int statusCode;
  final DriverLocation? data;
  final bool success;

  TrackingResponse({
    required this.message,
    required this.statusCode,
    this.data,
    required this.success,
  });

  factory TrackingResponse.fromJson(Map<String, dynamic> json) {
    return TrackingResponse(
      message: json['message'] ?? '',
      statusCode: json['statusCode'] ?? 0,
      data: json['data'] != null ? DriverLocation(
        rideId: json['data']['rideId'] ?? '',
        driverEmail: json['data']['driverEmail'] ?? '',
        latitude: json['data']['latitude']?.toDouble() ?? 0.0,
        longitude: json['data']['longitude']?.toDouble() ?? 0.0,
        timestamp: json['data']['timestamp'] != null 
            ? DateTime.parse(json['data']['timestamp'])
            : DateTime.now(),
      ) : null,
      success: json['success'] ?? false,
    );
  }
}

class TrackingService {
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();
  final WebSocketService _webSocketService = WebSocketService();

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

  /// Send tracking data via WebSocket (preferred method)
  Future<bool> sendTrackingDataViaWebSocket({
    required String rideId,
    required double latitude,
    required double longitude,
    double? speed,
  }) async {
    try {
      final userRole = await _authManager.getUserRole();
      final userEmail = await _authManager.getUserEmail();

      if (userRole?.toUpperCase() != 'DRIVER' || userEmail == null) {
        print('Only drivers can send location updates');
        return false;
      }

      if (!_webSocketService.isConnected) {
        print('WebSocket not connected, falling back to REST API');
        return await updateDriverLocation(
          rideId: rideId,
          latitude: latitude,
          longitude: longitude,
        );
      }

      await _webSocketService.sendTrackingData(
        rideId,
        latitude,
        longitude,
        speed: speed,
      );

      return true;
    } catch (e) {
      print('Error sending tracking data via WebSocket: $e');
      // Fallback to REST API
      return await updateDriverLocation(
        rideId: rideId,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  /// Subscribe to tracking data for a ride (for passengers)
  Future<void> subscribeToTracking({
    required String rideId,
    required Function(Map<String, dynamic>) onLocationUpdate,
  }) async {
    try {
      if (!_webSocketService.isConnected) {
        print('WebSocket not connected, cannot subscribe to tracking');
        return;
      }

      _webSocketService.onTrackingDataReceived = onLocationUpdate;
      await _webSocketService.connectForTracking(rideId);
    } catch (e) {
      print('Error subscribing to tracking: $e');
    }
  }

  /// Unsubscribe from tracking data
  void unsubscribeFromTracking() {
    _webSocketService.onTrackingDataReceived = null;
  }

  /// Initialize WebSocket for tracking
  Future<void> initializeWebSocket() async {
    try {
      final token = await _authManager.getToken();
      final userEmail = await _authManager.getUserEmail();

      if (token == null || userEmail == null) {
        print('Cannot initialize WebSocket: missing token or email');
        return;
      }

      await _webSocketService.initialize(
        _appConfig.getBaseUrl(),
        token,
        userEmail,
      );
    } catch (e) {
      print('Error initializing WebSocket for tracking: $e');
    }
  }

  /// Check if WebSocket is connected
  bool get isWebSocketConnected => _webSocketService.isConnected;
}
