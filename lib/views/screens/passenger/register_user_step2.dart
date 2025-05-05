import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sharexe/controllers/register_controller.dart';
import 'package:sharexe/models/registration_data.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:sharexe/views/widgets/register_form_step2.dart';
import 'package:flutter/foundation.dart';
import 'package:sharexe/app_route.dart';

class RegisterUserStep2 extends StatefulWidget {
  final String role;
  final RegistrationData data;

  const RegisterUserStep2({super.key, required this.role, required this.data});

  @override
  State<RegisterUserStep2> createState() => _RegisterUserStep2State();
}

class _RegisterUserStep2State extends State<RegisterUserStep2> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _errorMessage = '';
  String _avatarPath = '';
  String? _licenseImagePath = '';
  String? _vehicleImagePath = '';
  late RegisterController _controller;
  late RegistrationData _data;

  @override
  void initState() {
    super.initState();
    _controller = RegisterController(AuthService());
    _data = widget.data;
    _phoneController.text = _data.phone ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _addImage(String type) async {
    if (kIsWeb) {
      setState(() {
        _avatarPath = 'fake_avatar_path.jpg';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chọn ảnh (giả lập)')),
        );
      });
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _avatarPath = pickedFile.path;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã chọn ảnh')),
          );
        });
      }
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _data.phone = _phoneController.text.trim();
      _data.avatarImage = _avatarPath.isEmpty ? '' : _avatarPath;

      if (_data.email.isEmpty || _data.password.isEmpty || _data.fullName.isEmpty) {
        _setError('Vui lòng điền đầy đủ thông tin ở bước trước');
        return;
      }

      await _controller.register(
        context,
        _data.email,
        _data.password,
        _data.fullName,
        _data.phone,
        _data.avatarImage,
        widget.role,
        _setError,
      );
      setState(() {});
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, AppRoute.loginPassenger);
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
                  Text(
                    'Đăng ký tài khoản hành khách',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  RegisterFormStep2(
                    formKey: _formKey,
                    phoneController: _phoneController,
                    errorMessage: _errorMessage,
                    onRegister: _controller.isLoading ? () {} : _register,
                    onLogin: _navigateToLogin,
                    onAddAvatar: () => _addImage('avatar'),
                    avatarPath: _avatarPath,
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