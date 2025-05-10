import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import '../../../services/auth_service.dart';
import '../../../controllers/auth_controller.dart';
import '../../../app_route.dart';
import '../../../views/screens/passenger/edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthController _authController = AuthController(AuthService());
  
  bool _isLoading = true;
  UserProfile? _userProfile;
  String _errorMessage = '';

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
        } else {
          _errorMessage = response.message;
          
          // Nếu phiên đăng nhập hết hạn, tự động đăng xuất và chuyển hướng về màn hình đăng nhập
          if (response.message.contains('Phiên đăng nhập đã hết hạn')) {
            _handleSessionExpired();
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  void _logout() async {
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
  }

  // Xử lý phiên đăng nhập hết hạn
  void _handleSessionExpired() async {
    try {
      // Đăng xuất
      await _authController.logout(context);
      
      if (mounted) {
        // Hiển thị dialog thông báo
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Phiên đăng nhập hết hạn'),
            content: const Text('Phiên đăng nhập của bạn đã hết hạn. Vui lòng đăng nhập lại để tiếp tục sử dụng ứng dụng.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // NavigationHelper sẽ xử lý việc điều hướng từ logout()
                },
                child: const Text('Đăng nhập lại'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Lỗi khi xử lý phiên hết hạn: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00AEEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hồ sơ hành khách'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
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
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFF00AEEF),
                                      width: 4,
                                    ),
                                  ),
                                  child: _userProfile!.avatarUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            _userProfile!.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Color(0xFF00AEEF),
                                              );
                                            },
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Color(0xFF00AEEF),
                                            ),
                                          ),
                                        ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00AEEF),
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
                                        '5.0',
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
                                        color: Color(0xFF00AEEF),
                                      ),
                                      onPressed: () {
                                        // Edit avatar functionality
                                        if (_userProfile != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditProfileScreen(
                                                userProfile: _userProfile!,
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
                              title: 'Lịch sử chuyến đi',
                              onTap: () {
                                Navigator.pushNamed(context, PassengerRoutes.bookings);
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
                              icon: Icons.edit,
                              title: 'Chỉnh sửa thông tin',
                              onTap: () {
                                if (_userProfile != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfileScreen(
                                        userProfile: _userProfile!,
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
                              icon: Icons.payment,
                              title: 'Phương thức thanh toán',
                              onTap: () {
                                // Payment methods
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
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF00AEEF)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF00AEEF)),
          ],
        ),
      ),
    );
  }
} 