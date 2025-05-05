import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/custom_button.dart';
import 'package:sharexe/views/widgets/custom_text_field.dart';

class LoginFormContainer extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String errorMessage;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const LoginFormContainer({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.errorMessage,
    required this.isLoading,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: emailController,
              labelText: 'Nhập email:',
              hintText: 'Email...',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            SizedBox(height: screenHeight * 0.02),
            CustomTextField(
              controller: passwordController,
              labelText: 'Nhập mật khẩu:',
              hintText: '********',
              prefixIcon: Icons.lock_outlined,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                if (value.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                }
                return null;
              },
            ),
            SizedBox(height: screenHeight * 0.02),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            SizedBox(height: screenHeight * 0.02),
            CustomButton(
              text: 'Đăng nhập',
              backgroundColor: const Color(0xFF003087),
              textColor: Colors.white,
              onPressed: isLoading ? () {} : onLogin,
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chưa có tài khoản? ',
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: onRegister,
                  child: const Text(
                    'Đăng ký',
                    style: TextStyle(
                      color: Color(0xFF003087),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}