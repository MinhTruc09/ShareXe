import 'package:flutter/material.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/models/passenger.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/utils/navigation_helper.dart';

class AuthController {
  final AuthService service;
  bool isLoading = false;

  AuthController(this.service);

  Future<void> logout(BuildContext context) async {
    isLoading = true;
    try {
      await service.logout();
      isLoading = false;
      
      // Điều hướng về màn hình chọn vai trò và xóa tất cả màn hình khác trong stack
      NavigationHelper.navigateAndClearStack(context, AppRoute.role);
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