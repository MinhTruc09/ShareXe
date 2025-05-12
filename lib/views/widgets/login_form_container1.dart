import 'package:flutter/material.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/views/widgets/custom_button.dart';
import 'package:sharexe/views/widgets/custom_text_field1.dart';

class LoginFormContainer1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String errorMessage;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const LoginFormContainer1({
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField1(
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
            CustomTextField1(
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
            SizedBox(height: screenHeight * 0.01),
            
            // Thêm nút quên mật khẩu
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoute.forgotPassword);
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00B7FF),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(10, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: screenHeight * 0.01),
            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: screenHeight * 0.02),
            CustomButton(
              text: 'Đăng nhập',
              backgroundColor: const Color(0xFF00B7FF),
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
                      color: Color(0xFF00B7FF),
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