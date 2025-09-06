import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import '../../../services/auth_service.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/sharexe_background2.dart';
import 'dart:developer' as developer;
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

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
      developer.log(
        'Profile response: ${response.success}, ${response.message}',
        name: 'profile_screen',
      );
      if (response.data != null) {
        developer.log(
          'Profile data: id=${response.data?.id}, role=${response.data?.role}, status=${response.data?.status}',
          name: 'profile_screen',
        );
        developer.log(
          'Profile URLs: avatar=${response.data?.avatarUrl}, license=${response.data?.licenseImageUrl}, vehicle=${response.data?.vehicleImageUrl}',
          name: 'profile_screen',
        );
      } else {
        developer.log('Profile data is null', name: 'profile_screen');
      }

      setState(() {
        if (response.success && response.data != null) {
          _userProfile = response.data;
          _isLoading = false;
          _isError = false;
        } else {
          _isLoading = false;
          _isError = true;
          _errorMessage =
              response.data == null
                  ? 'Không thể tải thông tin hồ sơ. Vui lòng đăng nhập lại.'
                  : response.message;
        }
      });
    } catch (e) {
      developer.log(
        'Error loading user profile: $e',
        name: 'profile_screen',
        error: e,
      );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã bật chế độ debug')));
    }
  }

  void _logout() async {
    // Hiển thị dialog xác nhận trước khi đăng xuất
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
          ),
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  void _editProfile() {
    try {
      if (_userProfile != null) {
        print(
          'Điều hướng đến màn hình chỉnh sửa hồ sơ với dữ liệu: ${_userProfile!.fullName}',
        );

        // Sử dụng try-catch khi điều hướng để bắt lỗi
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      DriverEditProfileScreen(userProfile: _userProfile!),
            ),
          ).then((value) {
            print('Quay lại từ màn hình chỉnh sửa, kết quả: $value');
            _loadUserProfile();
          });
        } catch (e) {
          print('LỖI KHI ĐIỀU HƯỚNG: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi mở màn hình chỉnh sửa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('userProfile là null, không thể điều hướng');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể tải thông tin hồ sơ. Vui lòng thử lại sau.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        // Thử tải lại hồ sơ
        _loadUserProfile();
      }
    } catch (e) {
      print('LỖI NGHIÊM TRỌNG: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi không xác định: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground2(
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
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
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
                      const SizedBox(height: 20),
                      _buildVerificationStatus(),
                      const SizedBox(height: 20),
                      _buildVehicleInfo(),
                      const SizedBox(height: 20),
                      _buildMenuOptions(),
                      const SizedBox(height: 20),
                      if (_isDebugMode) _buildDebugInfo(),
                      const SizedBox(height: 20), // Thêm padding cuối để tránh overflow
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF002D72),
            Color(0xFF004A9F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF002D72).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar với border gradient
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade200],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    _userProfile?.avatarUrl != null
                        ? NetworkImage(_userProfile!.avatarUrl!)
                        : null,
                child:
                    _userProfile?.avatarUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            // Tên với hiệu ứng
            Text(
              _userProfile?.fullName ?? 'Tài xế',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Email với icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  _userProfile?.email ?? 'Email chưa cung cấp',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Số điện thoại với icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  _userProfile?.phoneNumber ?? 'Chưa có số điện thoại',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Nút chỉnh sửa với gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade100],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit, color: Color(0xFF002D72)),
                label: const Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(
                    color: Color(0xFF002D72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStatus() {
    final status = _userProfile?.status?.toUpperCase();
    final statusColor = _getVerificationStatusColor(_userProfile?.status);
    final statusText = _getVerificationStatusText(_userProfile?.status);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    status == 'APPROVED'
                        ? Icons.verified_user
                        : status == 'PENDING'
                            ? Icons.hourglass_empty
                            : Icons.cancel,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trạng thái xác minh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == 'APPROVED')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (status == 'PENDING')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Hồ sơ của bạn đang được xem xét. Bạn sẽ nhận được thông báo khi được phê duyệt.',
                        style: TextStyle(fontSize: 14, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            if (status == 'REJECTED')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Hồ sơ của bạn đã bị từ chối. Vui lòng liên hệ hỗ trợ để biết thêm chi tiết.',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            if (status == 'APPROVED')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tài xế của bạn đã được xác minh và có thể bắt đầu nhận chuyến đi.',
                        style: TextStyle(fontSize: 14, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    // Check if we have any vehicle information to display
    bool hasVehicleInfo =
        _userProfile?.vehicleImageUrl != null ||
        _userProfile?.licenseImageUrl != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF002D72),
                  Color(0xFF004A9F),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Thông tin phương tiện',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            style: TextStyle(color: Colors.grey.shade600),
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

                if (hasVehicleInfo) ...[
                  // Grid layout cho thông tin xe
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.2, // Giảm tỷ lệ để tránh overflow
                    children: [
                      _buildInfoCard(
                        icon: Icons.confirmation_number,
                        label: 'Biển số xe',
                        value: _userProfile?.licensePlate ?? 'Chưa cập nhật',
                        color: const Color(0xFF002D72),
                      ),
                      _buildInfoCard(
                        icon: Icons.branding_watermark,
                        label: 'Hãng xe',
                        value: _userProfile?.brand ?? 'Chưa cập nhật',
                        color: const Color(0xFF004A9F),
                      ),
                      _buildInfoCard(
                        icon: Icons.directions_car,
                        label: 'Mẫu xe',
                        value: _userProfile?.model ?? 'Chưa cập nhật',
                        color: const Color(0xFF0066CC),
                      ),
                      _buildInfoCard(
                        icon: Icons.palette,
                        label: 'Màu xe',
                        value: _userProfile?.color ?? 'Chưa cập nhật',
                        color: const Color(0xFF0080FF),
                      ),
                      _buildInfoCard(
                        icon: Icons.people,
                        label: 'Số chỗ ngồi',
                        value: '${_userProfile?.numberOfSeats ?? 0} chỗ',
                        color: const Color(0xFF00A0FF),
                      ),
                      _buildInfoCard(
                        icon: Icons.verified_user,
                        label: 'Trạng thái',
                        value: _getVerificationStatusText(_userProfile?.status),
                        color: _getVerificationStatusColor(_userProfile?.status),
                      ),
                    ],
                  ),
                  if (_userProfile?.status?.toUpperCase() == 'APPROVED') ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Tài xế của bạn đã được xác minh và có thể bắt đầu nhận chuyến đi.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có thông tin phương tiện',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng cập nhật thông tin để có thể tham gia làm tài xế.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Giảm padding từ 16 xuống 12
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12), // Giảm border radius
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6, // Giảm blur radius
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4), // Giảm padding
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6), // Giảm border radius
                ),
                child: Icon(
                  icon,
                  size: 14, // Giảm kích thước icon
                  color: color,
                ),
              ),
              const SizedBox(width: 6), // Giảm spacing
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11, // Giảm font size
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Giảm spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 12, // Giảm font size
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1, // Giảm maxLines từ 2 xuống 1
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF002D72),
                  Color(0xFF004A9F),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cài đặt tài khoản',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.directions_car,
                  title: 'Quản lý phương tiện',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.verified_user,
                  title: 'Tài liệu xác minh',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.lock,
                  title: 'Đổi mật khẩu',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Cài đặt',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help,
                  title: 'Trợ giúp & Hỗ trợ',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chức năng đang phát triển')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  onTap: _logout,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (color ?? const Color(0xFF002D72)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon, 
                    size: 20, 
                    color: color ?? const Color(0xFF002D72),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: color ?? Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right, 
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Card(
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              'Vehicle Info:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'License Plate: ${_userProfile?.licensePlate}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Brand: ${_userProfile?.brand}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Model: ${_userProfile?.model}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Color: ${_userProfile?.color}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Seats: ${_userProfile?.numberOfSeats}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'URLs:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
