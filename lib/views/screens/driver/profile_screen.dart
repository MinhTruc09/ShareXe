import 'package:flutter/material.dart';
import '../../../models/driver_profile.dart';
import '../../../services/driver_profile_service.dart';
import '../../../app_route.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final DriverProfileService _profileService = DriverProfileService();
  bool _isLoading = true;
  DriverProfile? _driverProfile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileService.getDriverProfile();
      
      setState(() {
        _driverProfile = profile;
        _isLoading = false;
      });
      
      if (profile == null) {
        _errorMessage = 'Không thể tải thông tin tài khoản';
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi khi tải thông tin: $e';
      });
    }
  }

  void _navigateToEditProfile() {
    if (_driverProfile != null) {
      Navigator.pushNamed(
        context,
        AppRoute.editProfileDriver,
        arguments: _driverProfile,
      ).then((_) => _loadProfile());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ tài xế'),
        backgroundColor: const Color(0xFF002D72),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading || _driverProfile == null
                ? null
                : _navigateToEditProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _driverProfile?.avatarUrl != null
                ? NetworkImage(_driverProfile!.avatarUrl!)
                : null,
            child: _driverProfile?.avatarUrl == null
                ? const Icon(Icons.person, size: 60, color: Color(0xFF002D72))
                : null,
          ),
          const SizedBox(height: 24),
          
          // Name
          Text(
            _driverProfile?.fullName ?? 'N/A',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF002D72).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF002D72)),
            ),
            child: Text(
              'Tài xế',
              style: TextStyle(
                color: const Color(0xFF002D72),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Information cards
          _buildInfoCard(
            title: 'Thông tin cá nhân',
            items: [
              InfoItem(
                icon: Icons.email_outlined,
                title: 'Email',
                value: _driverProfile?.email ?? 'N/A',
              ),
              InfoItem(
                icon: Icons.phone_outlined,
                title: 'Số điện thoại',
                value: _driverProfile?.phoneNumber ?? 'N/A',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoCard(
            title: 'Thông tin phương tiện',
            items: [
              InfoItem(
                icon: Icons.directions_car_outlined,
                title: 'Loại xe',
                value: _driverProfile?.vehicleType ?? 'Chưa cập nhật',
              ),
              InfoItem(
                icon: Icons.confirmation_number_outlined,
                title: 'Biển số xe',
                value: _driverProfile?.licensePlate ?? 'Chưa cập nhật',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Vehicle and license images
          if (_driverProfile?.vehicleImageUrl != null ||
              _driverProfile?.licenseImageUrl != null)
            _buildImagesCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<InfoItem> items,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002D72),
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildInfoItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(InfoItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(
            item.icon,
            color: const Color(0xFF002D72),
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                item.value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giấy tờ & Phương tiện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002D72),
              ),
            ),
            const SizedBox(height: 16),
            if (_driverProfile?.vehicleImageUrl != null)
              _buildImageSection(
                title: 'Hình ảnh phương tiện',
                imageUrl: _driverProfile!.vehicleImageUrl!,
              ),
            if (_driverProfile?.licenseImageUrl != null)
              _buildImageSection(
                title: 'Giấy phép lái xe',
                imageUrl: _driverProfile!.licenseImageUrl!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required String imageUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class InfoItem {
  final IconData icon;
  final String title;
  final String value;

  InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
} 