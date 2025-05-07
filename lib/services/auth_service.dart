import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/passenger.dart';
import '../models/driver.dart';
import 'auth_manager.dart';
import '../utils/app_config.dart';

class AuthService {
  // Sử dụng cấu hình tập trung từ AppConfig
  final AppConfig _appConfig = AppConfig();
  final AuthManager _authManager = AuthManager();

  // Getter để lấy baseUrl từ AppConfig
  String get baseUrl => '${_appConfig.apiBaseUrl}/api';

  Future<Passenger> login(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': role}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final parsed = Passenger.fromJson(jsonResponse);

        // Extract token data
        if (parsed.success && parsed.data != null) {
          final token = parsed.data!.token;
          final userEmail = parsed.data!.email;
          final userRole = parsed.data!.role;

          if (token != null && userEmail != null && userRole != null) {
            // Save auth data using AuthManager
            await _authManager.saveAuthData(token, userEmail, userRole);
          }
        }

        return parsed;
      } else {
        return Passenger(
          success: false,
          message: 'Login failed: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      return Passenger(
        success: false,
        message: 'Failed to connect to the server: $e',
        data: null,
      );
    }
  }

  Future<Passenger> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? avatarImagePath,
    String? role, // Thêm role để xác định passenger hoặc driver
  }) async {
    try {
      if (kIsWeb) {
        final response = await http.post(
          Uri.parse(
            '$baseUrl/auth/${role == 'DRIVER' ? 'driver' : 'passenger'}-register',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'fullName': fullName,
            'phone': phone,
            'avatarImage': avatarImagePath ?? '',
          }),
        );
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          return Passenger.fromJson(jsonResponse);
        } else {
          return Passenger(
            success: false,
            message: 'Registration failed: ${response.statusCode}',
            data: null,
          );
        }
      } else {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
            '$baseUrl/auth/${role == 'DRIVER' ? 'driver' : 'passenger'}-register',
          ),
        );
        request.fields['email'] = email;
        request.fields['password'] = password;
        request.fields['fullName'] = fullName;
        request.fields['phone'] = phone;
        if (avatarImagePath != null) {
          request.files.add(
            await http.MultipartFile.fromPath('avatarImage', avatarImagePath),
          );
        }
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(responseBody);
          return Passenger.fromJson(jsonResponse);
        } else {
          return Passenger(
            success: false,
            message: 'Registration failed: ${response.statusCode}',
            data: null,
          );
        }
      }
    } catch (e) {
      return Passenger(
        success: false,
        message: 'Failed to connect to the server: $e',
        data: null,
      );
    }
  }

  Future<Passenger> registerDriver({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String licenseImagePath,
    required String vehicleImagePath,
    String? avatarImagePath,
    String? licensePlate,
    String? licenseNumber,
    String? licenseType,
    String? licenseExpiry,
    String? vehicleType,
    String? vehicleColor,
    String? vehicleModel,
    String? vehicleYear,
  }) async {
    try {
      if (kIsWeb) {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/driver-register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'fullName': fullName,
            'phone': phone,
            'avatarImage': avatarImagePath ?? '',
            'licenseImage': 'fake_license.jpg', // Giả lập trên web
            'vehicleImage': 'fake_vehicle.jpg', // Giả lập trên web
            'licensePlate': licensePlate ?? '',
            'licenseNumber': licenseNumber ?? '',
            'licenseType': licenseType ?? '',
            'licenseExpiry': licenseExpiry ?? '',
            'vehicleType': vehicleType ?? '',
            'vehicleColor': vehicleColor ?? '',
            'vehicleModel': vehicleModel ?? '',
            'vehicleYear': vehicleYear ?? '',
          }),
        );
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          return Passenger.fromJson(jsonResponse);
        } else {
          return Passenger(
            success: false,
            message: 'Registration failed: ${response.statusCode}',
            data: null,
          );
        }
      } else {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/auth/driver-register'),
        );
        request.fields['email'] = email;
        request.fields['password'] = password;
        request.fields['fullName'] = fullName;
        request.fields['phone'] = phone;
        request.fields['licensePlate'] = licensePlate ?? '';
        request.fields['licenseNumber'] = licenseNumber ?? '';
        request.fields['licenseType'] = licenseType ?? '';
        request.fields['licenseExpiry'] = licenseExpiry ?? '';
        request.fields['vehicleType'] = vehicleType ?? '';
        request.fields['vehicleColor'] = vehicleColor ?? '';
        request.fields['vehicleModel'] = vehicleModel ?? '';
        request.fields['vehicleYear'] = vehicleYear ?? '';

        if (avatarImagePath != null) {
          request.files.add(
            await http.MultipartFile.fromPath('avatarImage', avatarImagePath),
          );
        }
        request.files.add(
          await http.MultipartFile.fromPath('licenseImage', licenseImagePath),
        );
        request.files.add(
          await http.MultipartFile.fromPath('vehicleImage', vehicleImagePath),
        );
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(responseBody);
          return Passenger.fromJson(jsonResponse);
        } else {
          return Passenger(
            success: false,
            message: 'Registration failed: ${response.statusCode}',
            data: null,
          );
        }
      }
    } catch (e) {
      return Passenger(
        success: false,
        message: 'Failed to connect to the server: $e',
        data: null,
      );
    }
  }

  // Lấy thông tin driver từ server
  Future<Driver?> getDriverProfile() async {
    final token = await _authManager.getToken();

    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Driver.fromJson(jsonResponse['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('Failed to get driver profile: $e');
      return null;
    }
  }

  // Cập nhật trạng thái của tài xế (hoạt động/ngừng hoạt động)
  Future<bool> updateDriverStatus(bool isActive) async {
    final token = await _authManager.getToken();

    if (token == null) return false;

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/driver/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isActive': isActive}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to update driver status: $e');
      return false;
    }
  }

  // Cập nhật vị trí của tài xế
  Future<bool> updateDriverLocation(double lat, double lng) async {
    final token = await _authManager.getToken();

    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/driver/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Failed to update driver location: $e');
      return false;
    }
  }

  // Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      return await _authManager.validateSession();
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  // Get current user's role
  Future<String?> getCurrentUserRole() async {
    try {
      return await _authManager.getUserRole();
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  // Get JWT token for API requests
  Future<String?> getAuthToken() async {
    try {
      return await _authManager.getToken();
    } catch (e) {
      print("Error getting auth token: $e");
      return null;
    }
  }

  // Sign out user
  Future<void> logout() async {
    try {
      await _authManager.logout();
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  // Lấy thông tin người dùng chung
  Future<Passenger> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token == null) {
      return Passenger(success: false, message: 'No token found', data: null);
    }

    try {
      final endpoint = role?.toUpperCase() == 'DRIVER' ? 'driver' : 'passenger';
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Passenger(
          success: true,
          message: 'Profile fetched successfully',
          data: jsonResponse['data'],
        );
      } else {
        return Passenger(
          success: false,
          message: 'Failed to get profile: ${response.statusCode}',
          data: null,
        );
      }
    } catch (e) {
      return Passenger(
        success: false,
        message: 'Failed to get user profile: $e',
        data: null,
      );
    }
  }
}
