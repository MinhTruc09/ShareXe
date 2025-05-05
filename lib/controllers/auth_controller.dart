import 'package:flutter/material.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/models/passenger.dart';

class AuthController {
  final AuthService service;
  bool isLoading = false;

  AuthController(this.service);

  Future<void> logout() async {
    isLoading = true;
    try {
      await service.logout();
      isLoading = false;
      return;
    } catch (e) {
      isLoading = false;
      throw Exception('Lỗi khi đăng xuất: $e');
    }
  }

  Future<LoginData?> getUserProfile() async {
    isLoading = true;
    try {
      final response = await service.getUserProfile();
      isLoading = false;
      if (response.success && response.data != null) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      isLoading = false;
      throw Exception('Lỗi khi lấy thông tin người dùng: $e');
    }
  }
} 