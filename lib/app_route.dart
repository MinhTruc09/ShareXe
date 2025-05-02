import 'package:flutter/material.dart';
import 'views/screens/splash_screen.dart';
import 'views/screens/role_screen.dart';
import 'views/screens/passenger/splash_pscreen.dart';
import 'views/screens/passenger/login_passenger.dart';

class AppRoute {
  static const String splash = '/';
  static const String role = '/role';
  static const String splashPassenger = '/splash_passenger';
  static const String loginPassenger = '/login_passenger';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case role:
        return MaterialPageRoute(builder: (_) => const RoleScreen());
      case splashPassenger:
        return MaterialPageRoute(builder: (_) => const SplashPscreen());
      case loginPassenger:
        return MaterialPageRoute(builder: (_) => const LoginPassenger());
      default:
        return null;
    }
  }
} 