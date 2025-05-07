import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/custom_button.dart';
import 'package:sharexe/views/widgets/custom_text_field1.dart';

class RegisterDriverFormStep2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController licensePlateController;
  final String errorMessage;
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onAddAvatar;
  final VoidCallback onAddLicenseImage;
  final VoidCallback onAddVehicleImage;
  final String avatarPath;
  final String licenseImagePath;
  final String vehicleImagePath;

  const RegisterDriverFormStep2({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.licensePlateController,
    required this.errorMessage,
    required this.onRegister,
    required this.onLogin,
    required this.onAddAvatar,
    required this.onAddLicenseImage,
    required this.onAddVehicleImage,
    required this.avatarPath,
    required this.licenseImagePath,
    required this.vehicleImagePath,
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
            CustomTextField1(
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
            CustomTextField1(
              controller: licensePlateController,
              labelText: 'Biển số xe:',
              hintText: 'Nhập biển số xe của bạn',
              prefixIcon: Icons.directions_car_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập biển số xe';
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
                    color: Color(0xFF003087),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                CustomButton(
                  text: 'Thêm',
                  backgroundColor: const Color(0xFF003087),
                  textColor: Colors.white,
                  onPressed: onAddAvatar,
                  width: screenWidth * 0.3,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn ảnh bằng lái:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Color(0xFF003087),
                  ),
                ),
                CustomButton(
                  text: 'Thêm',
                  backgroundColor: const Color(0xFF003087),
                  textColor: Colors.white,
                  onPressed: onAddLicenseImage,
                  width: screenWidth * 0.3,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ],
            ),
            if (licenseImagePath.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Text(
                  'Ảnh bằng lái: $licenseImagePath',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn ảnh xe:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Color(0xFF003087),
                  ),
                ),
                CustomButton(
                  text: 'Thêm',
                  backgroundColor: const Color(0xFF003087),
                  textColor: Colors.white,
                  onPressed: onAddVehicleImage,
                  width: screenWidth * 0.3,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ],
            ),
            if (vehicleImagePath.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Text(
                  'Ảnh xe: $vehicleImagePath',
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
              backgroundColor: const Color(0xFFFFD600),
              textColor: const Color(0xFF333333),
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