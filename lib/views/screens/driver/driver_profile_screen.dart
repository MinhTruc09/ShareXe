import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import '../../../services/auth_service.dart';
import '../../../controllers/auth_controller.dart';
import '../../../app_route.dart';
import '../../widgets/sharexe_background1.dart';
import 'dart:developer' as developer;

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  _DriverProfileScreenState createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthController _authController = AuthController(AuthService());
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  bool _isDebugMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final response = await _profileService.getUserProfile();
      
      // Log response for debugging
      developer.log('Profile response: ${response.success}, ${response.message}', name: 'profile_screen');
      if (response.data != null) {
        developer.log('Profile data: id=${response.data?.id}, role=${response.data?.role}, status=${response.data?.status}', 
          name: 'profile_screen');
        developer.log('Profile URLs: avatar=${response.data?.avatarUrl}, license=${response.data?.licenseImageUrl}, vehicle=${response.data?.vehicleImageUrl}', 
          name: 'profile_screen');
      }
      
      setState(() {
        if (response.success && response.data != null) {
          _userProfile = response.data;
          _isLoading = false;
          _isError = false;
        } else {
          _isLoading = false;
          _isError = true;
          _errorMessage = response.message;
        }
      });
    } catch (e) {
      developer.log('Error loading user profile: $e', name: 'profile_screen', error: e);
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Không thể tải thông tin tài xế: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông tin người dùng: $e')),
        );
      }
    }
  }

  void _toggleDebugMode() {
    setState(() {
      _isDebugMode = !_isDebugMode;
    });
    
    if (_isDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bật chế độ debug')),
      );
    }
  }

  void _logout() async {
    // Hiển thị dialog xác nhận trước khi đăng xuất
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Đóng dialog
                
                // Tiến hành đăng xuất
    try {
      await _authController.logout(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi khi đăng xuất: $e')),
        );
      }
    }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  String _getVerificationStatusText(String? status) {
    if (status == null) return 'Chưa xác minh';
    
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Đang chờ xác minh';
      case 'APPROVED':
        return 'Đã xác minh';
      case 'REJECTED':
        return 'Bị từ chối';
      default:
        return 'Chưa xác minh';
    }
  }

  Color _getVerificationStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground1(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF002D72),
          title: const Text('Hồ sơ tài xế'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _toggleDebugMode,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUserProfile,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _isError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadUserProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF002D72),
                          ),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 16),
                        _buildVerificationStatus(),
                        const SizedBox(height: 16),
                        _buildVehicleInfo(),
                        const SizedBox(height: 16),
                        _buildMenuOptions(),
                        if (_isDebugMode) _buildDebugInfo(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _userProfile?.avatarUrl != null
                  ? NetworkImage(_userProfile!.avatarUrl!)
                  : null,
              child: _userProfile?.avatarUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _userProfile?.fullName ?? 'Tài xế',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userProfile?.email ?? 'Email chưa cung cấp',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userProfile?.phoneNumber ?? 'Chưa có số điện thoại',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  DriverRoutes.editProfile,
                  arguments: _userProfile,
                ).then((_) => _loadUserProfile());
              },
              icon: const Icon(Icons.edit),
              label: const Text('Chỉnh sửa hồ sơ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF002D72),
                side: const BorderSide(color: Color(0xFF002D72)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStatus() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng thái xác minh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002D72),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _userProfile?.status?.toUpperCase() == 'APPROVED'
                      ? Icons.verified_user
                      : Icons.pending,
                  color: _getVerificationStatusColor(_userProfile?.status),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _getVerificationStatusText(_userProfile?.status),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getVerificationStatusColor(_userProfile?.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_userProfile?.status?.toUpperCase() == 'PENDING')
              const Text(
                'Hồ sơ của bạn đang được xem xét. Bạn sẽ nhận được thông báo khi được phê duyệt.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            if (_userProfile?.status?.toUpperCase() == 'REJECTED')
              const Text(
                'Hồ sơ của bạn đã bị từ chối. Vui lòng liên hệ hỗ trợ để biết thêm chi tiết.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    // Check if we have any vehicle information to display
    bool hasVehicleInfo = _userProfile?.vehicleImageUrl != null || _userProfile?.licenseImageUrl != null;
    
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                if (_userProfile?.vehicleImageUrl != null)
                  Container(
                    width: double.infinity,
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(_userProfile!.vehicleImageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có ảnh phương tiện',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (_userProfile?.licenseImageUrl != null) 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giấy phép lái xe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D72),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(_userProfile!.licenseImageUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: hasVehicleInfo 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              icon: Icons.directions_car,
                              label: 'Loại xe',
                              value: _userProfile?.role == 'DRIVER' 
                                  ? 'Ô tô' 
                                  : 'Không xác định',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.description,
                              label: 'Mô tả',
                              value: 'Xe 4-7 chỗ',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              icon: Icons.verified_user,
                              label: 'Trạng thái',
                              value: _getVerificationStatusText(_userProfile?.status),
                            ),
                            if (_userProfile?.status?.toUpperCase() == 'APPROVED')
                              ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Tài xế của bạn đã được xác minh và có thể bắt đầu nhận chuyến đi.',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                          ],
                        )
                      : const Center(
                          child: Text(
                            'Bạn chưa cung cấp thông tin phương tiện. Vui lòng cập nhật thông tin để có thể tham gia làm tài xế.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOptions() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cài đặt tài khoản',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002D72),
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              icon: Icons.directions_car,
              title: 'Quản lý phương tiện',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            const Divider(),
            _buildMenuItem(
              icon: Icons.verified_user,
              title: 'Tài liệu xác minh',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            const Divider(),
            _buildMenuItem(
              icon: Icons.lock,
              title: 'Đổi mật khẩu',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            const Divider(),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Cài đặt',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            const Divider(),
            _buildMenuItem(
              icon: Icons.help,
              title: 'Trợ giúp & Hỗ trợ',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
            const Divider(),
            _buildMenuItem(
              icon: Icons.logout,
              title: 'Đăng xuất',
              onTap: _logout,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: color ?? const Color(0xFF002D72),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Divider(color: Colors.white54),
            Text(
              'ID: ${_userProfile?.id}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Name: ${_userProfile?.fullName}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Email: ${_userProfile?.email}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Phone: ${_userProfile?.phoneNumber}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Role: ${_userProfile?.role}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Status: ${_userProfile?.status}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'URLs:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              'Avatar: ${_userProfile?.avatarUrl}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'License: ${_userProfile?.licenseImageUrl}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Vehicle: ${_userProfile?.vehicleImageUrl}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadUserProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }
} 