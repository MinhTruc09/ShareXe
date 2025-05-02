import 'package:flutter/material.dart';

class LoginPassenger extends StatelessWidget {
  const LoginPassenger({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập Khách hàng')),
      body: const Center(
        child: Text('Đây là màn hình đăng nhập khách hàng'),
      ),
    );
  }
}
