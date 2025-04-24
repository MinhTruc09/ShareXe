import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Chuyển hướng sau 2 giây
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/home'); // Thay '/home' bằng route của bạn
    });

    return Scaffold(
      body: Stack(
        children: [
          // Nền xanh lam
          Container(
            color: const Color(0xFF00AEEF), // Điều chỉnh màu xanh lam giống hình
          ),
          // Logo ở trung tâm
          Center(
            child: Image.asset(
              'assets/images/sharexe.png', // Đường dẫn đến logo
              width: screenWidth * 0.5, // 50% chiều rộng màn hình
              height: screenHeight * 0.2, // 20% chiều cao màn hình
            ),
          ),
          // Đám mây góc trên bên trái
          Positioned(
            top: 0,
            left: 0,
            child: FractionallySizedBox(
              widthFactor: 0.4, // 40% chiều rộng màn hình
              child: Image.asset(
                'assets/images/cloud_upleft.png',
                fit: BoxFit.contain, // Đảm bảo hình ảnh không bị méo
              ),
            ),
          ),
          // Đám mây góc trên bên phải
          Positioned(
            top: 0,
            right: 0,
            child: FractionallySizedBox(
              widthFactor: 0.3, // 30% chiều rộng màn hình
              child: Image.asset(
                'assets/images/cloud_upright.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Đám mây ở dưới cùng
          Positioned(
            bottom: 0,
            left: 0,
            right: 0, // Đám mây dưới cùng kéo dài toàn bộ chiều rộng
            child: FractionallySizedBox(
              widthFactor: 1.0, // 100% chiều rộng màn hình
              heightFactor: 0.25, // 25% chiều cao màn hình
              child: Image.asset(
                'assets/images/cloud_bottom.png',
                fit: BoxFit.cover, // Đảm bảo hình ảnh trải đều
              ),
            ),
          ),
        ],
      ),
    );
  }
}