import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'auth_manager.dart';

class ProfileService {
  final String baseUrl = 'https://209b-2405-4803-c83c-6d40-8464-c5f5-c484-d512.ngrok-free.app/api';
  final AuthManager _authManager = AuthManager();

  // Fetch user profile information
  Future<ProfileResponse> getUserProfile() async {
    try {
      final token = await _authManager.getToken();
      final role = await _authManager.getUserRole();
      
      if (token == null) {
        return ProfileResponse(
          message: 'Authentication token not found',
          data: UserProfile(
            id: 0,
            fullName: '',
            email: '',
            phoneNumber: '',
            role: '',
          ),
          success: false,
        );
      }
      
      // Determine the endpoint based on user role
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
        return ProfileResponse.fromJson(jsonResponse);
      } else {
        return ProfileResponse(
          message: 'Failed to fetch profile: ${response.statusCode}',
          data: UserProfile(
            id: 0,
            fullName: '',
            email: '',
            phoneNumber: '',
            role: '',
          ),
          success: false,
        );
      }
    } catch (e) {
      return ProfileResponse(
        message: 'Error: $e',
        data: UserProfile(
          id: 0,
          fullName: '',
          email: '',
          phoneNumber: '',
          role: '',
        ),
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
      final token = await _authManager.getToken();
      final role = await _authManager.getUserRole();
      
      if (token == null) {
        return ProfileResponse(
          message: 'Authentication token not found',
          data: UserProfile(
            id: 0,
            fullName: '',
            email: '',
            phoneNumber: '',
            role: '',
          ),
          success: false,
        );
      }
      
      final uri = Uri.parse('$baseUrl/user/update-profile');
      
      var request = http.MultipartRequest('POST', uri);
      
      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      // Add text fields if provided
      if (fullName != null) {
        request.fields['fullName'] = fullName;
      }
      
      if (phoneNumber != null) {
        request.fields['phone'] = phoneNumber;
      }
      
      // Add files if provided
      if (avatarImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'avatarImage', 
          avatarImage.path,
        ));
      }
      
      // Only add these fields for driver role
      if (role?.toUpperCase() == 'DRIVER') {
        if (licenseImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'licenseImage', 
            licenseImage.path,
          ));
        }
        
        if (vehicleImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'vehicleImage', 
            vehicleImage.path,
          ));
        }
      }
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return ProfileResponse.fromJson(jsonResponse);
      } else {
        return ProfileResponse(
          message: 'Failed to update profile: ${response.statusCode} - ${response.body}',
          data: UserProfile(
            id: 0,
            fullName: '',
            email: '',
            phoneNumber: '',
            role: '',
          ),
          success: false,
        );
      }
    } catch (e) {
      return ProfileResponse(
        message: 'Error updating profile: $e',
        data: UserProfile(
          id: 0,
          fullName: '',
          email: '',
          phoneNumber: '',
          role: '',
        ),
        success: false,
      );
    }
  }
} 