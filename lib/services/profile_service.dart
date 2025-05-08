import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'auth_manager.dart';
import '../utils/http_client.dart';
import '../utils/app_config.dart';

class ProfileService {
  final AuthManager _authManager = AuthManager();
  final ApiClient _apiClient = ApiClient();
  final AppConfig _appConfig = AppConfig();

  // Giả lập dữ liệu người dùng khi không có kết nối
  UserProfile _getMockUserProfile(String role) {
    return UserProfile(
      id: 101,
      fullName:
          role.toUpperCase() == 'DRIVER' ? 'Tài Xế Demo' : 'Khách Hàng Demo',
      email:
          role.toUpperCase() == 'DRIVER'
              ? 'driver@example.com'
              : 'passenger@example.com',
      phoneNumber: '0123456789',
      role: role.toUpperCase(),
    );
  }

  // Fetch user profile information
  Future<ProfileResponse> getUserProfile() async {
    try {
      final role = await _authManager.getUserRole();

      // Determine the endpoint based on user role
      final endpoint = role?.toUpperCase() == 'DRIVER' ? 'driver' : 'passenger';

      try {
        final response = await _apiClient.get('/$endpoint/profile');

        if (response.statusCode == 200) {
          try {
            final jsonResponse = jsonDecode(response.body);
            return ProfileResponse.fromJson(jsonResponse);
          } catch (e) {
            print('❌ Lỗi phân tích dữ liệu người dùng: $e');
            // Return mock profile for demonstration
            return ProfileResponse(
              message: 'Đã tải hồ sơ demo',
              data: _getMockUserProfile(role ?? 'PASSENGER'),
              success: true,
            );
          }
        } else {
          print('❌ Lỗi lấy hồ sơ người dùng: ${response.statusCode}');
          // Return mock profile for demonstration
          return ProfileResponse(
            message: 'Đã tải hồ sơ demo (lỗi API: ${response.statusCode})',
            data: _getMockUserProfile(role ?? 'PASSENGER'),
            success: true,
          );
        }
      } on http.ClientException catch (e) {
        print('❌ Lỗi kết nối khi lấy hồ sơ: $e');

        if (e.toString().contains('Connection refused') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection timed out')) {
          print('⚠️ Đang sử dụng dữ liệu người dùng giả cho demo');
          return ProfileResponse(
            message:
                'Không thể kết nối tới máy chủ. Đang hiển thị dữ liệu ngoại tuyến.',
            data: _getMockUserProfile(role ?? 'PASSENGER'),
            success: true,
            isOffline: true,
          );
        }

        return ProfileResponse(
          message: 'Lỗi kết nối: $e',
          data: _getMockUserProfile(role ?? 'PASSENGER'),
          success: false,
        );
      }
    } catch (e) {
      print('❌ Lỗi khi lấy thông tin người dùng: $e');
      final role = await _authManager.getUserRole();
      return ProfileResponse(
        message: 'Lỗi: $e',
        data: _getMockUserProfile(role ?? 'PASSENGER'),
        success: false,
      );
    }
  }

  // Update user profile with multipart request (for image uploads)
  Future<ProfileResponse> updateUserProfile({
    File? avatarImage,
    File? licenseImage,
    File? vehicleImage,
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final role = await _authManager.getUserRole();

      // Prepare fields
      final Map<String, String> fields = {};
      if (fullName != null) {
        fields['fullName'] = fullName;
      }

      if (phoneNumber != null) {
        fields['phone'] = phoneNumber;
      }

      // Prepare files
      final Map<String, String> files = {};
      if (avatarImage != null) {
        files['avatarImage'] = avatarImage.path;
      }

      // Only add these fields for driver role
      if (role?.toUpperCase() == 'DRIVER') {
        if (licenseImage != null) {
          files['licenseImage'] = licenseImage.path;
        }

        if (vehicleImage != null) {
          files['vehicleImage'] = vehicleImage.path;
        }
      }

      try {
        // Send the request using ApiClient
        final streamedResponse = await _apiClient.multipartRequest(
          'POST',
          '/user/update-profile',
          fields: fields,
          files: files,
        );

        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          return ProfileResponse.fromJson(jsonResponse);
        } else {
          print('❌ Cập nhật hồ sơ thất bại: ${response.statusCode}');
          return ProfileResponse(
            message: 'Cập nhật thất bại: Mã lỗi ${response.statusCode}',
            data: _getMockUserProfile(role ?? 'PASSENGER'),
            success: false,
          );
        }
      } on http.ClientException catch (e) {
        print('❌ Lỗi kết nối khi cập nhật hồ sơ: $e');

        if (e.toString().contains('Connection refused') ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection timed out')) {
          return ProfileResponse(
            message:
                'Không thể kết nối tới máy chủ để cập nhật. Vui lòng thử lại sau.',
            data: _getMockUserProfile(role ?? 'PASSENGER'),
            success: false,
            isOffline: true,
          );
        }

        return ProfileResponse(
          message: 'Lỗi kết nối: $e',
          data: _getMockUserProfile(role ?? 'PASSENGER'),
          success: false,
        );
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật hồ sơ: $e');
      final role = await _authManager.getUserRole();
      return ProfileResponse(
        message: 'Lỗi: $e',
        data: _getMockUserProfile(role ?? 'PASSENGER'),
        success: false,
      );
    }
  }
}
