import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../views/widgets/sharexe_background2.dart';
import '../../../services/auth_service.dart';
import 'dart:developer' as developer;
import 'package:sharexe/views/widgets/custom_button.dart';
import 'package:sharexe/views/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> 
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = '';
  
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Cài đặt hiệu ứng
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  void _handleBack() {
    Navigator.pop(context);
  }
  
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
      
      // Log it
      developer.log('Password reset requested for: ${_emailController.text}', 
        name: 'forgot_password_screen');
      
      // Show success state
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      
      // Reset the animation and start it again for success screen
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      developer.log('Error in password reset: $e', 
        name: 'forgot_password_screen', error: e);
        
      setState(() {
        _isLoading = false;
        _errorMessage = 'Có lỗi xảy ra: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SharexeBackground2(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF002D72),
          title: const Text('Quên mật khẩu'),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _isSuccess 
                      ? _buildSuccessContent(screenHeight)
                      : _buildResetForm(screenHeight, screenWidth),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildResetForm(double screenHeight, double screenWidth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo và hình ảnh minh họa
        Hero(
          tag: 'forgot_password_logo',
          child: Container(
            height: screenHeight * 0.22,
            width: screenHeight * 0.22,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: screenHeight * 0.12,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.lock_reset,
                      size: screenHeight * 0.1,
                      color: const Color(0xFF002D72),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.04),
        
        // Form Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
                      const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D72),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      
                      // Mô tả
                      const Text(
                        'Vui lòng nhập email đã đăng ký. Chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu đến email của bạn.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      
                      // Trường nhập email
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
                      
                      // Hiển thị lỗi nếu có
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      SizedBox(height: screenHeight * 0.03),
                      
                      // Nút gửi yêu cầu
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF002D72)),
                              ),
                            )
                          : CustomButton(
                              text: 'Gửi yêu cầu',
                              backgroundColor: const Color(0xFF002D72),
                              textColor: Colors.white,
                              onPressed: _handleResetPassword,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Quay lại đăng nhập
                      Center(
                        child: TextButton.icon(
                          onPressed: _handleBack,
                          icon: const Icon(
                            Icons.arrow_back,
                            size: 16,
                            color: Color(0xFF002D72),
                          ),
                          label: const Text(
                            'Quay lại đăng nhập',
                            style: TextStyle(
                              color: Color(0xFF002D72),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSuccessContent(double screenHeight) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Biểu tượng thành công
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
          ),
          const SizedBox(height: 30),
          
          // Tiêu đề thành công
          const Text(
            'Yêu cầu đã được gửi!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF002D72),
            ),
          ),
          const SizedBox(height: 20),
          
          // Mô tả thành công
          Text(
            'Chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến email ${_emailController.text}.\n\nVui lòng kiểm tra hộp thư của bạn và làm theo hướng dẫn.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          
          // Nút quay lại đăng nhập
          CustomButton(
            text: 'Quay lại đăng nhập',
            backgroundColor: const Color(0xFF002D72),
            textColor: Colors.white,
            onPressed: _handleBack,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          
          const SizedBox(height: 20),
          
          // Gợi ý kiểm tra spam
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.amber.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Nếu không thấy email trong hộp thư đến, hãy kiểm tra thư mục spam hoặc junk.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 