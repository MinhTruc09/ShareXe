import 'package:flutter/material.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/controllers/login_controller.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/views/widgets/login_form_container1.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:sharexe/views/widgets/login_form_container.dart';
import 'package:sharexe/views/widgets/sharexe_background2.dart';

class LoginDriver extends StatefulWidget {
  const LoginDriver({super.key});

  @override
  State<LoginDriver> createState() => _LoginDriverState();
}

class _LoginDriverState extends State<LoginDriver> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = LoginController(AuthService());
  
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = '';
      });

      try {
        _controller.login(
          context,
          _emailController.text.trim(),
          _passwordController.text,
          _setError,
          role: 'DRIVER',
        );
      } catch (e) {
        _setError('Lỗi kết nối: $e');
      }
    }
  }

  void _navigateToRegister() {
    Navigator.pushReplacementNamed(
      context,
      AppRoute.registerDriverStep1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SharexeBackground2(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.04,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/drilogo1.png',
                    width: screenWidth * 0.5,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Xin chào tài xế, vui lòng đăng nhập',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  LoginFormContainer1(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    errorMessage: _errorMessage,
                    isLoading: _controller.isLoading,
                    onLogin: _login,
                    onRegister: _navigateToRegister,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 