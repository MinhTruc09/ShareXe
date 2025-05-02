import 'package:flutter/material.dart';

class SharexeBackground extends StatelessWidget {
  final Widget child;
  const SharexeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFF00AEEF),
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Đám mây góc trên bên trái
              Positioned(
                top: 0,
                left: 0,
                child: Image.asset(
                  'assets/images/cloud_upleft.png',
                  width: screenWidth * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
              // Đám mây góc trên bên phải
              Positioned(
                top: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/cloud_upright.png',
                  width: screenWidth * 0.5,
                  fit: BoxFit.contain,
                ),
              ),
              // Đám mây dưới cùng
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Image.asset(
                  'assets/images/cloud_bottom.png',
                  height: screenHeight * 0.4,
                  fit: BoxFit.cover,
                ),
              ),
              // Widget con (ví dụ logo, form, ...)
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }
} 