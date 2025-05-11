import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import '../../../services/auth_service.dart';
import '../../../controllers/auth_controller.dart';
import '../../../app_route.dart';
import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import 'edit_profile_screen.dart';
import 'vehicle_info_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthController _authController = AuthController(AuthService());
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  UserProfile? _userProfile;
  String _errorMessage = '';
  String? _rejectionReason;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _profileService.getUserProfile();

      setState(() {
        _isLoading = false;
        if (response.success) {
          _userProfile = response.data;

          // Nếu tài xế bị từ chối, tìm lý do từ chối trong thông báo
          if (_userProfile?.status == 'REJECTED') {
            _loadRejectionReason();
          }
        } else {
          _errorMessage = response.message;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _loadRejectionReason() async {
    try {
      setState(() {
        _isLoadingNotifications = true;
      });

      // Lấy danh sách thông báo của người dùng
      final notifications = await _notificationService.getNotifications();

      // Tìm thông báo gần nhất về việc từ chối tài xế
      final rejectionNotification =
          notifications
              .where(
                (notification) =>
                    notification.type == 'DRIVER_REJECTED' &&
                    notification.referenceId == _userProfile!.id,
              )
              .toList();

      if (rejectionNotification.isNotEmpty) {
        // Sắp xếp theo thời gian, lấy thông báo mới nhất
        rejectionNotification.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
        final latestNotification = rejectionNotification.first;

        // Lấy lý do từ nội dung thông báo
        final content = latestNotification.content;
        if (content.contains('Lý do:')) {
          setState(() {
            _rejectionReason = content.split('Lý do:').last.trim();
          });
        }
      }

      setState(() {
        _isLoadingNotifications = false;
      });
    } catch (e) {
      print('Lỗi khi tải thông báo: $e');
      setState(() {
        _isLoadingNotifications = false;
      });
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
      // NavigationHelper sẽ xử lý việc điều hướng, không cần NavigatorPushReplacement
    } catch (e) {
      if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002D72),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hồ sơ tài xế'),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _userProfile == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // User Profile Header with avatar and rating
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Column(
                        children: [
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
                                child:
                                    _userProfile!.avatarUrl != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            _userProfile!.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.white,
                                              );
                                            },
                                          ),
                                        )
                                        : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.yellow,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '4.8',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      if (_userProfile != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    DriverEditProfileScreen(
                                                      userProfile:
                                                          _userProfile!,
                                                    ),
                                          ),
                                        ).then((updated) {
                                          if (updated == true) {
                                            // Reload profile if updated
                                            _loadUserProfile();
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Xin chào bạn, ${_userProfile!.fullName}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userProfile!.phoneNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Hiển thị trạng thái phê duyệt tài xế
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _userProfile!.status == 'APPROVED'
                                      ? Colors.green
                                      : _userProfile!.status == 'PENDING'
                                      ? Colors.orange
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _userProfile!.status == 'APPROVED'
                                      ? Icons.check_circle
                                      : _userProfile!.status == 'PENDING'
                                      ? Icons.hourglass_top
                                      : Icons.cancel,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _userProfile!.status == 'APPROVED'
                                      ? 'Tài xế đã được duyệt'
                                      : _userProfile!.status == 'PENDING'
                                      ? 'Đang chờ phê duyệt'
                                      : 'Hồ sơ bị từ chối',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu Items in a White Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hiển thị thông tin trạng thái phê duyệt chi tiết
                          if (_userProfile!.status != 'APPROVED')
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    _userProfile!.status == 'PENDING'
                                        ? Colors.orange[50]
                                        : Colors.red[50],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _userProfile!.status == 'PENDING'
                                            ? Icons.info_outline
                                            : Icons.warning_amber_outlined,
                                        color:
                                            _userProfile!.status == 'PENDING'
                                                ? Colors.orange[700]
                                                : Colors.red[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _userProfile!.status == 'PENDING'
                                              ? 'Hồ sơ của bạn đang được xem xét'
                                              : 'Hồ sơ của bạn bị từ chối',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                _userProfile!.status ==
                                                        'PENDING'
                                                    ? Colors.orange[700]
                                                    : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _userProfile!.status == 'PENDING'
                                        ? 'Chúng tôi đang xem xét thông tin của bạn. Quá trình này có thể mất từ 1-3 ngày làm việc. Bạn sẽ nhận được thông báo khi hồ sơ được duyệt.'
                                        : _rejectionReason != null
                                        ? 'Hồ sơ của bạn chưa đáp ứng đủ yêu cầu. Lý do: $_rejectionReason. Vui lòng cập nhật thông tin theo yêu cầu.'
                                        : 'Hồ sơ của bạn chưa đáp ứng đủ yêu cầu. Vui lòng kiểm tra thông báo để biết chi tiết, và cập nhật hình ảnh giấy phép lái xe và phương tiện rõ ràng hơn.',
                                    style: TextStyle(
                                      color:
                                          _userProfile!.status == 'PENDING'
                                              ? Colors.orange[800]
                                              : Colors.red[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_userProfile!.status == 'REJECTED')
                                    OutlinedButton(
                                      onPressed: () {
                                        if (_userProfile != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      DriverEditProfileScreen(
                                                        userProfile:
                                                            _userProfile!,
                                                      ),
                                            ),
                                          ).then((updated) {
                                            if (updated == true) {
                                              _loadUserProfile();
                                            }
                                          });
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[700],
                                      ),
                                      child: const Text('Cập nhật hồ sơ'),
                                    ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Tổng quát',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.history,
                            title: 'Lịch sử chuyến',
                            onTap: () {
                              // Navigate to history screen
                              if (_userProfile!.status != 'APPROVED') {
                                _showRequireApprovalDialog(context);
                                return;
                              }
                              // TODO: Chuyển đến màn hình lịch sử chuyến
                            },
                            isDisabled: _userProfile!.status != 'APPROVED',
                          ),
                          _buildMenuItem(
                            icon: Icons.car_repair,
                            title: 'Thông tin xe',
                            onTap: () {
                              if (_userProfile != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => VehicleInfoScreen(
                                          userProfile: _userProfile!,
                                        ),
                                  ),
                                );
                              }
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.directions_car,
                            title: 'Tạo chuyến đi mới',
                            onTap: () {
                              if (_userProfile!.status != 'APPROVED') {
                                _showRequireApprovalDialog(context);
                                return;
                              }
                              // TODO: Chuyển đến màn hình tạo chuyến đi
                            },
                            isDisabled: _userProfile!.status != 'APPROVED',
                          ),
                          _buildMenuItem(
                            icon: Icons.credit_card,
                            title: 'Thanh toán',
                            onTap: () {
                              if (_userProfile!.status != 'APPROVED') {
                                _showRequireApprovalDialog(context);
                                return;
                              }
                              // TODO: Chuyển đến màn hình thanh toán
                            },
                            isDisabled: _userProfile!.status != 'APPROVED',
                          ),
                          _buildMenuItem(
                            icon: Icons.settings,
                            title: 'Cài đặt',
                            onTap: () {
                              // Navigate to settings screen
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.logout,
                            title: 'Đăng xuất',
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                    // Help Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Hỗ trợ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          _buildMenuItem(
                            icon: Icons.language,
                            title: 'Ngôn ngữ',
                            onTap: () {
                              // Language settings
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.support,
                            title: 'Trung tâm hỗ trợ',
                            onTap: () {
                              // Help center
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.share,
                            title: 'Chia sẻ phản hồi',
                            onTap: () {
                              // Share feedback
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDisabled ? Colors.grey[400] : Colors.black54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDisabled ? Colors.grey[400] : Colors.black87,
                ),
              ),
            ),
            if (isDisabled)
              Icon(Icons.lock_outline, size: 16, color: Colors.grey[400])
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black45,
              ),
          ],
        ),
      ),
    );
  }

  void _showRequireApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                _userProfile!.status == 'PENDING'
                    ? Icons.hourglass_top
                    : Icons.error_outline,
                color:
                    _userProfile!.status == 'PENDING'
                        ? Colors.orange
                        : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _userProfile!.status == 'PENDING'
                    ? 'Đang chờ phê duyệt'
                    : 'Chưa được phê duyệt',
                style: TextStyle(
                  color:
                      _userProfile!.status == 'PENDING'
                          ? Colors.orange[700]
                          : Colors.red[700],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userProfile!.status == 'PENDING'
                    ? 'Tài khoản tài xế của bạn đang trong quá trình xét duyệt. Vui lòng đợi phê duyệt trước khi sử dụng các tính năng này.'
                    : _rejectionReason != null
                    ? 'Tài khoản của bạn chưa được duyệt. Lý do: $_rejectionReason'
                    : 'Tài khoản của bạn chưa được duyệt. Vui lòng kiểm tra thông báo và cập nhật hồ sơ.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (_userProfile!.status == 'REJECTED')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Để được phê duyệt, bạn cần:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildRequirementRow(
                      'Cập nhật thông tin cá nhân đầy đủ',
                      Icons.person,
                    ),
                    _buildRequirementRow(
                      'Tải lên giấy phép lái xe rõ ràng',
                      Icons.badge,
                    ),
                    _buildRequirementRow(
                      'Tải lên hình ảnh phương tiện rõ ràng',
                      Icons.directions_car,
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            if (_userProfile!.status == 'REJECTED')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DriverEditProfileScreen(
                            userProfile: _userProfile!,
                          ),
                    ),
                  ).then((updated) {
                    if (updated == true) {
                      _loadUserProfile();
                    }
                  });
                },
                style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
                child: const Text('Cập nhật hồ sơ'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _userProfile!.status == 'PENDING' ? 'Đã hiểu' : 'Đóng',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequirementRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }
}
