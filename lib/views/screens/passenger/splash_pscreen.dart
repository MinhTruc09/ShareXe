import 'package:flutter/material.dart';
import 'package:sharexe/views/theme/app_theme.dart';
import 'package:sharexe/views/widgets/sharexe_background.dart';
import 'login_passenger.dart';

class SplashPscreen extends StatelessWidget {
  const SplashPscreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Chuyển hướng sau 2 giây
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPassenger()),
        );
      }
    });
    return SharexeBackground(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/passlogo.png',
              width: screenWidth * 0.5,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'Error loading logo',
                  style: TextStyle(color: Colors.white),
                );
              },
            ),
            SizedBox(height: 5),
            Text("Đăng nhập với tư các khách hàng",style: appTheme.textTheme.titleMedium)
          ],
        ),
      ),
    );
  }
}