import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/custom_text_field.dart';
import 'package:sharexe/views/widgets/custom_button.dart';

class RegisterFormStep1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController fullNameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final String errorMessage;
  final VoidCallback onContinue;
  final VoidCallback onLogin;

  const RegisterFormStep1({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.fullNameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.errorMessage,
    required this.onContinue,
    required this.onLogin,
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
              controller: fullNameController,
              labelText: 'Nhập họ và tên:',
              hintText: 'Họ và tên...',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            SizedBox(height: screenHeight * 0.02),
            CustomTextField(
              controller: passwordController,
              labelText: 'Nhập mật khẩu:',
              hintText: '********',
              prefixIcon: Icons.lock_outline,
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
            CustomTextField(
              controller: confirmPasswordController,
              labelText: 'Xác nhận mật khẩu:',
              hintText: '********',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng xác nhận mật khẩu';
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
              text: 'Tiếp tục',
              backgroundColor: const Color(0xFF003087),
              textColor: Colors.white,
              onPressed: onContinue,
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Đã có tài khoản? ',
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: onLogin,
                  child: const Text(
                    'Đăng nhập',
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