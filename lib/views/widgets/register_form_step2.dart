import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/custom_text_field.dart';
import 'package:sharexe/views/widgets/custom_button.dart';

class RegisterFormStep2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final String errorMessage;
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onAddAvatar;
  final String avatarPath;

  const RegisterFormStep2({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.errorMessage,
    required this.onRegister,
    required this.onLogin,
    required this.onAddAvatar,
    required this.avatarPath,
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
              controller: phoneController,
              labelText: 'Nhập số điện thoại:',
              hintText: '0123456789',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn ảnh đại diện:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Color(0xFF00BFFF),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                CustomButton(
                  text: 'Thêm',
                  backgroundColor: const Color(0xFF00BFFF),
                  textColor: Colors.white,
                  onPressed: onAddAvatar,
                  width: screenWidth * 0.3, // Giới hạn chiều rộng để không chiếm toàn bộ Row
                  padding: const EdgeInsets.symmetric(vertical: 12), // Điều chỉnh padding để cân đối
                ),
              ],
            ),
            if (avatarPath.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Text(
                  'Ảnh đã chọn: $avatarPath',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            SizedBox(height: screenHeight * 0.02),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            SizedBox(height: screenHeight * 0.02),
            CustomButton(
              text: 'Đăng ký',
              backgroundColor: const Color(0xFF003087),
              textColor: Colors.white,
              onPressed: onRegister,
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