import 'package:flutter/material.dart';
import '../app_route.dart';

class NavigationHelper {
  /// Điều hướng đến màn hình mới và xóa tất cả màn hình trước đó
  /// Sử dụng khi chuyển từ màn hình đăng nhập -> home, hoặc đăng xuất -> màn hình role
  static void navigateAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      routeName, 
      (route) => false, // Xóa tất cả các màn hình trước đó
      arguments: arguments
    );
  }

  /// Điều hướng đến màn hình mới và thay thế màn hình hiện tại
  /// Sử dụng khi muốn thay thế màn hình hiện tại nhưng vẫn giữ lại stack điều hướng
  static void navigateReplace(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(
      context, 
      routeName,
      arguments: arguments
    );
  }

  /// Điều hướng đến màn hình mới và giữ màn hình hiện tại trong stack
  /// Sử dụng cho các màn hình chi tiết hoặc form chỉnh sửa
  static Future<T?> navigate<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed(
      context, 
      routeName,
      arguments: arguments
    );
  }
  
  /// Điều hướng đến màn hình mới và xóa tất cả màn hình cho đến một màn hình cụ thể
  /// Hữu ích khi muốn quay lại một màn hình cụ thể trong stack
  static void navigateAndRemoveUntil(BuildContext context, String routeName, String untilRouteName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      routeName, 
      (route) => route.settings.name == untilRouteName,
      arguments: arguments
    );
  }
  
  /// Đóng màn hình hiện tại và trả về kết quả
  static void goBack<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
  
  /// Kiểm tra xem có thể quay lại không
  static bool canGoBack(BuildContext context) {
    return Navigator.canPop(context);
  }
  
  /// Pop cho đến một route nhất định
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, (route) => route.settings.name == routeName);
  }

  // Điều hướng đến trang tạo chuyến đi mới
  static void navigateToCreateRide(BuildContext context) {
    Navigator.pushNamed(context, DriverRoutes.createRide);
  }
} 