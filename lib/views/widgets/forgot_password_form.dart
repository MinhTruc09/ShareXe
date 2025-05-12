import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/custom_button.dart';
import 'package:sharexe/views/widgets/custom_text_field.dart';

class ForgotPasswordForm extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onResetPassword;
  
  const ForgotPasswordForm({
    Key? key,
    required this.onBack,
    required this.onResetPassword,
  }) : super(key: key);

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isSuccess = false;
  
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Simulate API call with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Call the reset password function
      widget.onResetPassword(_emailController.text.trim());
      
      // Show success message
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Có lỗi xảy ra: $e';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _isSuccess ? _buildSuccessMessage() : _buildResetForm(screenHeight),
    );
  }

  Widget _buildResetForm(double screenHeight) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              'assets/images/forgot_password.png', // Add a forgot password illustration
              height: screenHeight * 0.15,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.lock_reset,
                size: screenHeight * 0.15,
                color: const Color(0xFF003087),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003087),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          const Text(
            'Vui lòng nhập email đã đăng ký. Chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu đến email của bạn.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          CustomTextField(
            controller: _emailController,
            labelText: 'Email của bạn:',
            hintText: 'Nhập email đã đăng ký...',
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
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: screenHeight * 0.03),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomButton(
                  text: 'Gửi yêu cầu',
                  backgroundColor: const Color(0xFF003087),
                  textColor: Colors.white,
                  onPressed: _handleResetPassword,
                ),
          SizedBox(height: screenHeight * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: widget.onBack,
                child: const Text(
                  'Quay lại đăng nhập',
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
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 80,
        ),
        const SizedBox(height: 20),
        const Text(
          'Yêu cầu đã được gửi!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003087),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến email ${_emailController.text}. Vui lòng kiểm tra hộp thư của bạn và làm theo hướng dẫn.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 30),
        CustomButton(
          text: 'Quay lại đăng nhập',
          backgroundColor: const Color(0xFF003087),
          textColor: Colors.white,
          onPressed: widget.onBack,
        ),
      ],
    );
  }
} 