import 'package:flutter/material.dart';
import '../widgets/sharexe_background.dart';
import 'role_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Chuyển hướng sau 2 giây
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RoleScreen()),
        );
      }
    });
    return SharexeBackground(
      child: Image.asset(
        'assets/images/sharexe.png',
        width: screenWidth * 0.4,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            'Error loading logo',
            style: TextStyle(color: Colors.white),
          );
        },
      ),
    );
  }
} 