import 'package:flutter/material.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/utils/navigation_helper.dart';

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
      print('🔑 Đang đăng nhập với vai trò: ${role ?? 'PASSENGER'}');
      final response = await service.login(email, password, role!);
      isLoading = false;

      if (response.success && response.data != null) {
        final data = response.data!;
        if (data.token == null || data.email == null || data.role == null) {
          onError('Dữ liệu trả về không đầy đủ');
          return;
        }
        
        // Token is already saved in AuthService.login
        
        // Kiểm tra vai trò người dùng có khớp với màn hình đăng nhập không
        if (role.toUpperCase() != data.role!.toUpperCase()) {
          onError('Bạn đang đăng nhập vào sai vai trò. Vui lòng sử dụng tài khoản ${role.toLowerCase() == 'driver' ? 'tài xế' : 'hành khách'}.');
          return;
        }
        
        print('✅ Đăng nhập thành công với vai trò: ${data.role}');
        
        // Điều hướng dựa vào vai trò - sử dụng NavigationHelper để xóa stack
        if (data.role!.toUpperCase() == 'DRIVER') {
          NavigationHelper.navigateAndClearStack(context, AppRoute.homeDriver);
        } else {
          NavigationHelper.navigateAndClearStack(context, AppRoute.homePassenger);
        }
      } else {
        print('❌ Đăng nhập thất bại: ${response.message}');
        onError(response.message);
      }
    } catch (e) {
      print('❌ Lỗi đăng nhập: $e');
      isLoading = false;
      onError('Lỗi kết nối, vui lòng thử lại: $e');
    }
  }
}