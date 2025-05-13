import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../services/auth_service.dart';
import '../../../app_route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  String _debugMessage = '';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Show splash for 2 seconds

      // Check if user is already logged in
      bool isLoggedIn = false;
      try {
        isLoggedIn = await _authService.isLoggedIn();
        if (kDebugMode) {
          setState(() {
            _debugMessage = 'Is logged in: $isLoggedIn';
          });
        }
        
        // Kiểm tra thêm nếu token hợp lệ
        if (isLoggedIn) {
          final token = await _authService.getAuthToken();
          if (token == null) {
            print('SplashScreen: Token is null despite isLoggedIn being true');
            isLoggedIn = false;
            await _authService.logout();
          }
        }
      } catch (e) {
        if (kDebugMode) {
          setState(() {
            _debugMessage = 'Error checking login: $e';
          });
        }
      }

      if (isLoggedIn) {
        // Get user role to determine which home screen to navigate to
        String? userRole;
        try {
          userRole = await _authService.getCurrentUserRole();
          if (kDebugMode) {
            setState(() {
              _debugMessage += '\nUser role: $userRole';
            });
          }
        } catch (e) {
          if (kDebugMode) {
            setState(() {
              _debugMessage += '\nError getting role: $e';
            });
          }
        }

        if (!mounted) return;

        if (userRole == 'PASSENGER') {
          Navigator.pushReplacementNamed(context, PassengerRoutes.home);
        } else if (userRole == 'DRIVER') {
          Navigator.pushReplacementNamed(context, DriverRoutes.home);
        } else {
          // If role is unknown, go to role selection screen
          Navigator.pushReplacementNamed(context, AppRoute.role);
        }
      } else {
        // Not logged in, go to role selection screen
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoute.role);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _debugMessage = 'Error: $e';
        });
      }
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
              'assets/images/logo.png', // Sử dụng logo.png có sẵn thay vì app_logo.png
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                if (kDebugMode) {
                  print('Error loading logo: $error');
                }
                return const Icon(
                  Icons.directions_car,
                  size: 150,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 60),
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            if (_hasError)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _checkLoginStatus();
                },
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
