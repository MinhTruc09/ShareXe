import 'package:flutter/material.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/models/passenger.dart';

class RegisterController {
  final AuthService _authService;
  bool _isLoading = false;

  RegisterController(this._authService);

  bool get isLoading => _isLoading;

  Future<void> register(
      BuildContext context,
      String email,
      String password,
      String fullName,
      String phone,
      String avatarImagePath,
      String role, // Thêm role
      Function(String) setError,
      {String? licenseImagePath, 
      String? vehicleImagePath, 
      String? licensePlate,
      String? licenseNumber,
      String? licenseType,
      String? licenseExpiry,
      String? vehicleType,
      String? vehicleColor,
      String? vehicleModel,
      String? vehicleYear}) async {
    _isLoading = true;
    try {
      Passenger result;
      if (role == 'DRIVER') {
        result = await _authService.registerDriver(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          licenseImagePath: licenseImagePath ?? '', // Sử dụng giá trị được truyền vào
          vehicleImagePath: vehicleImagePath ?? '', // Sử dụng giá trị được truyền vào
          avatarImagePath: avatarImagePath,
          licensePlate: licensePlate, // Thêm biển số xe
          licenseNumber: licenseNumber, // Thêm số giấy phép
          licenseType: licenseType, // Thêm loại giấy phép
          licenseExpiry: licenseExpiry, // Thêm ngày hết hạn giấy phép
          vehicleType: vehicleType, // Thêm loại xe
          vehicleColor: vehicleColor, // Thêm màu xe
          vehicleModel: vehicleModel, // Thêm model xe
          vehicleYear: vehicleYear, // Thêm năm sản xuất
        );
      } else {
        result = await _authService.register(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          avatarImagePath: avatarImagePath,
          role: role,
        );
      }

      if (result.success == true) {
        // Login automatically after successful registration
        final loginResult = await _authService.login(email, password);
        
        if (loginResult.success) {
          // Navigate directly to the home screen based on role
          if (role == 'DRIVER') {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/driver/home',
              (route) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/passenger/home',
              (route) => false,
            );
          }
        } else {
          // If auto-login fails, still go to login screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login_${role.toLowerCase()}',
            (route) => false,
          );
        }
      } else {
        setError(result.message ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      setError('Lỗi kết nối: $e');
    } finally {
      _isLoading = false;
    }
  }
}