import 'package:flutter/material.dart';
import 'package:sharexe/models/registration_data.dart';
import 'package:sharexe/views/widgets/register_form_step1.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/views/widgets/sharexe_background2.dart';

class RegisterDriverStep1 extends StatefulWidget {
  final Function(RegistrationData) onNext;

  const RegisterDriverStep1({super.key, required this.onNext});

  @override
  State<RegisterDriverStep1> createState() => _RegisterDriverStep1State();
}

class _RegisterDriverStep1State extends State<RegisterDriverStep1> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = RegistrationData(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      widget.onNext(data);
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, AppRoute.loginDriver);
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
                  Text(
                    'Đăng ký tài khoản tài xế',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  RegisterFormStep1(
                    formKey: _formKey,
                    emailController: _emailController,
                    fullNameController: _fullNameController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    phoneController: _phoneController,
                    errorMessage: _errorMessage,
                    onContinue: _submit,
                    onLogin: _navigateToLogin,
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