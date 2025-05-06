import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../app_route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds

    // Check if user is already logged in
    if (await _authService.isLoggedIn()) {
      // Get user role to determine which home screen to navigate to
      String? userRole = await _authService.getCurrentUserRole();
      
      if (!mounted) return;
      
      if (userRole == 'PASSENGER') {
        Navigator.pushReplacementNamed(context, AppRoute.homePassenger);
      } else if (userRole == 'DRIVER') {
        Navigator.pushReplacementNamed(context, AppRoute.homeDriver);
      } else {
        // If role is unknown, go to role selection screen
        Navigator.pushReplacementNamed(context, AppRoute.role);
      }
    } else {
      // Not logged in, go to role selection screen
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoute.role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00AEEF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'images/app_logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.directions_car,
                  size: 150,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'ShareXe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 