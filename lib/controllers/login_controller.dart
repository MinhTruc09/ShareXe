import 'package:flutter/material.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/app_route.dart';

class LoginController {
  final AuthService service;
  bool isLoading = false;

  LoginController(this.service);

  Future<void> login(
      BuildContext context,
      String email,
      String password,
      Function(String) onError,
      {String? role = 'PASSENGER'}) async {
    isLoading = true;
    onError(''); // Reset thông báo lỗi

    try {
      final response = await service.login(email, password, role!);
      isLoading = false;

      if (response.success && response.data != null) {
        final data = response.data!;
        if (data.token == null || data.email == null || data.role == null) {
          onError('Dữ liệu trả về không đầy đủ');
          return;
        }
        
        // Token is already saved in AuthService.login
        
        // Điều hướng dựa vào vai trò
        if (data.role!.toUpperCase() == 'DRIVER') {
          Navigator.pushReplacementNamed(context, AppRoute.homeDriver);
        } else {
          Navigator.pushReplacementNamed(context, AppRoute.homePassenger);
        }
      } else {
        onError(response.message);
      }
    } catch (e) {
      isLoading = false;
      onError('Lỗi kết nối, vui lòng thử lại: $e');
    }
  }
}