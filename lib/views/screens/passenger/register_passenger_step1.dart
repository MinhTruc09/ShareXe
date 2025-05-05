import 'package:flutter/material.dart';
import 'package:sharexe/models/registration_data.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:sharexe/views/widgets/register_form_step1.dart';
import 'package:sharexe/app_route.dart';

class RegisterPassengerStep1 extends StatefulWidget {
  final String role;
  final Function(RegistrationData) onNext;

  const RegisterPassengerStep1({super.key, required this.role, required this.onNext});

  @override
  State<RegisterPassengerStep1> createState() => _RegisterPassengerStep1State();
}

class _RegisterPassengerStep1State extends State<RegisterPassengerStep1> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _errorMessage = '';

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      final data = RegistrationData(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text, 
        phone: _phoneController.text,
      );
      widget.onNext(data);
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(
      context, 
      widget.role == 'DRIVER' ? AppRoute.loginDriver : AppRoute.loginPassenger
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determine title based on role
    String title = widget.role == 'DRIVER' ? 'Đăng ký tài khoản tài xế' : 'Đăng ký tài khoản hành khách';
    
    return SharexeBackground1(
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
                    title,
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
                    onContinue: _onNext,
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