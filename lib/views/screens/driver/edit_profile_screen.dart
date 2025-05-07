import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/driver_profile.dart';
import '../../../services/driver_profile_service.dart';

class DriverEditProfileScreen extends StatefulWidget {
  final DriverProfile userProfile;

  const DriverEditProfileScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<DriverEditProfileScreen> createState() => _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState extends State<DriverEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _licensePlateController = TextEditingController();
  
  final DriverProfileService _profileService = DriverProfileService();
  final ImagePicker _picker = ImagePicker();
  
  File? _avatarImage;
  File? _vehicleImage;
  File? _licenseImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.userProfile.fullName;
    _phoneController.text = widget.userProfile.phoneNumber;
    _vehicleTypeController.text = widget.userProfile.vehicleType ?? '';
    _licensePlateController.text = widget.userProfile.licensePlate ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, ImageType type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          switch (type) {
            case ImageType.avatar:
              _avatarImage = File(pickedFile.path);
              break;
            case ImageType.vehicle:
              _vehicleImage = File(pickedFile.path);
              break;
            case ImageType.license:
              _licenseImage = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể chọn ảnh: $e';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _profileService.updateDriverProfile(
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        vehicleType: _vehicleTypeController.text.isNotEmpty 
            ? _vehicleTypeController.text 
            : null,
        licensePlate: _licensePlateController.text.isNotEmpty 
            ? _licensePlateController.text 
            : null,
        avatarImage: _avatarImage,
        vehicleImage: _vehicleImage,
        licenseImage: _licenseImage,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Cập nhật thông tin thất bại';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  void _showImagePickerOptions(ImageType type) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chọn ảnh ${_getImageTypeTitle(type)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, type);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getImageTypeTitle(ImageType type) {
    switch (type) {
      case ImageType.avatar:
        return 'đại diện';
      case ImageType.vehicle:
        return 'phương tiện';
      case ImageType.license:
        return 'giấy phép lái xe';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cập nhật hồ sơ'),
        backgroundColor: const Color(0xFF002D72),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar section
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: () => _showImagePickerOptions(ImageType.avatar),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _avatarImage != null
                                      ? FileImage(_avatarImage!)
                                      : (widget.userProfile.avatarUrl != null
                                          ? NetworkImage(widget.userProfile.avatarUrl!)
                                          : null),
                                  child: _avatarImage == null && widget.userProfile.avatarUrl == null
                                      ? const Icon(Icons.person, size: 60, color: Color(0xFF002D72))
                                      : null,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF002D72),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nhấn để đổi ảnh đại diện',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    
                    // Personal Information Form
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin cá nhân',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002D72),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Full name field
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Họ tên',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập họ tên';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập số điện thoại';
                                }
                                return null;
                              },
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Vehicle Information Form
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin phương tiện',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002D72),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Vehicle type field
                            TextFormField(
                              controller: _vehicleTypeController,
                              decoration: const InputDecoration(
                                labelText: 'Loại phương tiện',
                                hintText: 'VD: Xe hơi 4 chỗ, Honda Wave,...',
                                prefixIcon: Icon(Icons.directions_car),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // License plate field
                            TextFormField(
                              controller: _licensePlateController,
                              decoration: const InputDecoration(
                                labelText: 'Biển số xe',
                                hintText: 'VD: 51F-123.45',
                                prefixIcon: Icon(Icons.confirmation_number),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Image uploads
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hình ảnh phương tiện và giấy phép',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF002D72),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Vehicle Image
                            _buildImageUploadSection(
                              title: 'Hình ảnh phương tiện',
                              description: 'Tải lên hình ảnh phương tiện của bạn',
                              imagePath: _vehicleImage?.path,
                              networkImageUrl: widget.userProfile.vehicleImageUrl,
                              onTap: () => _showImagePickerOptions(ImageType.vehicle),
                            ),
                            
                            const Divider(height: 32),
                            
                            // License Image
                            _buildImageUploadSection(
                              title: 'Hình ảnh giấy phép lái xe',
                              description: 'Tải lên hình ảnh giấy phép lái xe của bạn',
                              imagePath: _licenseImage?.path,
                              networkImageUrl: widget.userProfile.licenseImageUrl,
                              onTap: () => _showImagePickerOptions(ImageType.license),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Update button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002D72),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _updateProfile,
                        child: const Text(
                          'Cập nhật thông tin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageUploadSection({
    required String title,
    required String description,
    String? imagePath,
    String? networkImageUrl,
    required VoidCallback onTap,
  }) {
    final hasImage = imagePath != null || networkImageUrl != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              image: hasImage
                  ? DecorationImage(
                      image: imagePath != null
                          ? FileImage(File(imagePath))
                          : NetworkImage(networkImageUrl!) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasImage
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chọn ảnh',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

enum ImageType {
  avatar,
  vehicle,
  license,
} 