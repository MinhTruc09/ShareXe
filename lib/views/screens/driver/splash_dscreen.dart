import 'package:flutter/material.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/views/widgets/sharexe_background2.dart';

import '../../theme/app_theme.dart';

class SplashDscreen extends StatefulWidget {
  const SplashDscreen({super.key});

  @override
  State<SplashDscreen> createState() => _SplashDscreenState();
}

class _SplashDscreenState extends State<SplashDscreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the login screen after a delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, AppRoute.loginDriver);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SharexeBackground2(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/drilogo.png',
              width: screenWidth *0.3,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 5),
            Text("Đăng nhập với tư các tài xế",style: appTheme.textTheme.titleMedium)
          ],
        ),
      ),
    );
  }
}