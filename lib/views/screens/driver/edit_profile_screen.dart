import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';

class DriverEditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  
  const DriverEditProfileScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<DriverEditProfileScreen> createState() => _DriverEditProfileScreenState();
}

class _DriverEditProfileScreenState extends State<DriverEditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  File? _avatarImage;
  File? _licenseImage;
  File? _vehicleImage;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedGender;
  
  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.userProfile.fullName;
    _phoneController.text = widget.userProfile.phoneNumber;
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage(ImageType type) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          switch (type) {
            case ImageType.avatar:
              _avatarImage = File(image.path);
              break;
            case ImageType.license:
              _licenseImage = File(image.path);
              break;
            case ImageType.vehicle:
              _vehicleImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
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
      final response = await _profileService.updateUserProfile(
        avatarImage: _avatarImage,
        licenseImage: _licenseImage,
        vehicleImage: _vehicleImage,
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thông tin thành công')),
          );
          Navigator.pop(context, true); // Pop with success result
        }
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Widget _buildImageUploadSection(String title, File? imageFile, Function() onTap, String buttonText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(buttonText, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text('Chọn ảnh', style: TextStyle(color: Theme.of(context).primaryColor)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D72),
        title: const Text('Chỉnh sửa hồ sơ tài xế'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Error message if any
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    
                    // Avatar selection
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.yellow,
                            border: Border.all(
                              color: Colors.purple,
                              width: 4,
                            ),
                          ),
                          child: _avatarImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _avatarImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.userProfile.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    widget.userProfile.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    color: Colors.amber,
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.add_a_photo,
                                size: 18,
                                color: Colors.blue,
                              ),
                              onPressed: () => _pickImage(ImageType.avatar),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Email field (non-editable)
                    TextFormField(
                      initialValue: widget.userProfile.email,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Full name field
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Họ tên',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Phone number field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Gender selection
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Giới tính',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'MALE',
                          child: Text('Nam'),
                        ),
                        DropdownMenuItem(
                          value: 'FEMALE',
                          child: Text('Nữ'),
                        ),
                        DropdownMenuItem(
                          value: 'OTHER',
                          child: Text('Khác'),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // License Image Upload
                    _buildImageUploadSection(
                      'Ảnh bằng lái',
                      _licenseImage,
                      () => _pickImage(ImageType.license),
                      'Tải lên ảnh bằng lái',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Vehicle Image Upload
                    _buildImageUploadSection(
                      'Ảnh phương tiện',
                      _vehicleImage,
                      () => _pickImage(ImageType.vehicle),
                      'Tải lên ảnh phương tiện',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Update button
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002D72),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Cập nhật',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

enum ImageType {
  avatar,
  license,
  vehicle,
} 