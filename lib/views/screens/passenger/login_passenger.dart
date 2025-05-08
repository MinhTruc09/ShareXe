import 'package:flutter/material.dart';
import 'package:sharexe/controllers/login_controller.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:sharexe/views/widgets/login_form_container.dart';
import 'package:sharexe/app_route.dart';

class LoginPassenger extends StatefulWidget {
  const LoginPassenger({super.key});

  @override
  State<LoginPassenger> createState() => _LoginPassengerState();
}

class _LoginPassengerState extends State<LoginPassenger> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  late LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(AuthService());
  }

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

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      await _controller.login(
        context,
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _setError,
      );
      setState(() {
        _errorMessage = _controller.isLoading ? 'Loading...' : _errorMessage;
      });
    }
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, PassengerRoutes.registerStep1);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
                  Image.asset(
                    'assets/images/passlogo1.png',
                    width: screenWidth * 0.7,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Xin chào bạn, vui lòng đăng nhập',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  LoginFormContainer(
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
