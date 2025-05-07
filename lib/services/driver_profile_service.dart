import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/driver_profile.dart';
import '../utils/http_client.dart';
import '../utils/app_config.dart';
import '../services/auth_manager.dart';

class DriverProfileService {
  final ApiClient _apiClient;
  final AppConfig _appConfig = AppConfig();
  final AuthManager _authManager = AuthManager();

  DriverProfileService() : _apiClient = ApiClient();
  Future<DriverProfile?> getDriverProfile() async {
    try {
      final response = await _apiClient.get(
        '/driver/profile',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (kDebugMode) {
          print('🧑‍✈️ Driver profile data: $jsonData');
        }
        return DriverProfile.fromJson(jsonData);
      } else {
        if (kDebugMode) {
          print('❌ Failed to get driver profile: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting driver profile: $e');
      }
      return null;
    }
  }

  // Update the driver profile
  Future<bool> updateDriverProfile({
    required String fullName,
    required String phoneNumber,
    String? vehicleType,
    String? licensePlate,
    File? avatarImage,
    File? vehicleImage,
    File? licenseImage,
  }) async {
    try {
      // Create a multipart request
      final uri = Uri.parse('${_appConfig.fullApiUrl}/driver/update-profile');
      final request = http.MultipartRequest('POST', uri);

      // Add auth headers
      final token = await _authManager.getToken();
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['fullName'] = fullName;
      request.fields['phoneNumber'] = phoneNumber;
      
      if (vehicleType != null) {
        request.fields['vehicleType'] = vehicleType;
      }
      
      if (licensePlate != null) {
        request.fields['licensePlate'] = licensePlate;
      }

      // Add files if provided
      if (avatarImage != null) {
        final avatarStream = http.ByteStream(avatarImage.openRead());
        final avatarLength = await avatarImage.length();
        final avatarMultipart = http.MultipartFile(
          'avatar',
          avatarStream,
          avatarLength,
          filename: 'avatar.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(avatarMultipart);
      }

      if (vehicleImage != null) {
        final vehicleStream = http.ByteStream(vehicleImage.openRead());
        final vehicleLength = await vehicleImage.length();
        final vehicleMultipart = http.MultipartFile(
          'vehicleImage',
          vehicleStream,
          vehicleLength,
          filename: 'vehicle.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(vehicleMultipart);
      }

      if (licenseImage != null) {
        final licenseStream = http.ByteStream(licenseImage.openRead());
        final licenseLength = await licenseImage.length();
        final licenseMultipart = http.MultipartFile(
          'licenseImage',
          licenseStream,
          licenseLength,
          filename: 'license.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(licenseMultipart);
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('📡 Update profile response: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating driver profile: $e');
      }
      return false;
    }
  }
} 