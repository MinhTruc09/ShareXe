import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sharexe/controllers/register_controller.dart';
import 'package:sharexe/models/registration_data.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/views/widgets/register_driver_form_step2.dart';
import 'package:sharexe/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:sharexe/views/widgets/sharexe_background2.dart';

class RegisterDriverStep2 extends StatefulWidget {
  final RegistrationData data;

  const RegisterDriverStep2({super.key, required this.data});

  @override
  State<RegisterDriverStep2> createState() => _RegisterDriverStep2State();
}

class _RegisterDriverStep2State extends State<RegisterDriverStep2> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _numberOfSeatsController = TextEditingController();
  final _controller = RegisterController(AuthService());
  
  String _errorMessage = '';
  String _avatarPath = '';
  String _licenseImagePath = '';
  String _vehicleImagePath = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _licensePlateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _numberOfSeatsController.dispose();
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
        if (type == 'avatar') _avatarPath = 'fake_avatar_path.jpg';
        if (type == 'license') _licenseImagePath = 'fake_license_path.jpg';
        if (type == 'vehicle') _vehicleImagePath = 'fake_vehicle_path.jpg';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chọn ảnh (giả lập)')),
        );
      });
    } else {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (type == 'avatar') _avatarPath = pickedFile.path;
          if (type == 'license') _licenseImagePath = pickedFile.path;
          if (type == 'vehicle') _vehicleImagePath = pickedFile.path;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã chọn ảnh')),
          );
        });
      }
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      widget.data.phone = _phoneController.text.trim();
      widget.data.avatarImage = _avatarPath.isEmpty ? '' : _avatarPath;
      widget.data.licensePlate = _licensePlateController.text.trim();
      widget.data.licenseImage = _licenseImagePath;
      widget.data.vehicleImage = _vehicleImagePath;

      // Kiểm tra dữ liệu cơ bản
      if (widget.data.email.isEmpty || widget.data.password.isEmpty || widget.data.fullName.isEmpty) {
        _setError('Vui lòng điền đầy đủ thông tin ở bước trước');
        return;
      }

      if (_licenseImagePath.isEmpty || _vehicleImagePath.isEmpty) {
        _setError('Vui lòng chọn ảnh bằng lái và ảnh xe');
        return;
      }

      await _controller.register(
        context,
        widget.data.email,
        widget.data.password,
        widget.data.fullName,
        widget.data.phone,
        widget.data.avatarImage,
        'DRIVER',
        _setError,
        licenseImagePath: widget.data.licenseImage,
        vehicleImagePath: widget.data.vehicleImage,
        licensePlate: widget.data.licensePlate,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        color: _colorController.text.trim(),
        numberOfSeats: int.tryParse(_numberOfSeatsController.text.trim()) ?? 0,
      );
      setState(() {});
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, AppRoute.loginDriver);
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
                    'Hoàn tất thông tin tài xế',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  RegisterDriverFormStep2(
                    formKey: _formKey,
                    phoneController: _phoneController,
                    licensePlateController: _licensePlateController,
                    brandController: _brandController,
                    modelController: _modelController,
                    colorController: _colorController,
                    numberOfSeatsController: _numberOfSeatsController,
                    errorMessage: _errorMessage,
                    onRegister: _controller.isLoading ? () {} : _register,
                    onLogin: _navigateToLogin,
                    onAddAvatar: () => _addImage('avatar'),
                    onAddLicenseImage: () => _addImage('license'),
                    onAddVehicleImage: () => _addImage('vehicle'),
                    avatarPath: _avatarPath,
                    licenseImagePath: _licenseImagePath,
                    vehicleImagePath: _vehicleImagePath,
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