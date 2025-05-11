import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/controllers/auth_controller.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/models/ride.dart';
import 'package:sharexe/services/notification_service.dart';
import 'package:intl/intl.dart';
import '../../../services/profile_service.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_manager.dart';
import 'package:flutter/foundation.dart';
import '../../../services/ride_service.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/date_picker.dart';
import '../../widgets/passenger_counter.dart';
import '../../widgets/ride_card.dart';
import 'passenger_main_screen.dart'; // Import TabNavigator từ passenger_main_screen.dart

class NewHomePscreen extends StatefulWidget {
  const NewHomePscreen({super.key});

  @override
  State<NewHomePscreen> createState() => _NewHomePscreenState();
}

class _NewHomePscreenState extends State<NewHomePscreen> {
  late AuthController _authController;
  final NotificationService _notificationService = NotificationService();
  final ProfileService _profileService = ProfileService();
  final AuthManager _authManager = AuthManager();
  final RideService _rideService = RideService();

  List<Ride> _availableRides = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  UserProfile? _userProfile;

  // Search parameters
  String _departure = '';
  String _destination = '';
  DateTime? _departureDate;
  int _passengerCount = 1;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
    _loadAvailableRides();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _profileService.getUserProfile();

      if (response.success) {
        setState(() {
          _userProfile = response.data;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadAvailableRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Fetching available rides from API...');
      final rides = await _rideService.getAvailableRides();

      print('✅ Successfully fetched ${rides.length} rides from API');

      if (mounted) {
        setState(() {
          _availableRides = rides;
          _isLoading = false;
        });

        if (rides.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không có chuyến xe phù hợp')),
          );
        }
      }
    } catch (e) {
      print('❌ Error fetching rides: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _availableRides = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách chuyến xe: $e')),
        );
      }
    }
  }

  Future<void> _refreshRides() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      print('🔄 Refreshing available rides from API...');
      final rides = await _rideService.getAvailableRides();

      print('✅ Successfully refreshed ${rides.length} rides from API');

      if (mounted) {
        setState(() {
          _availableRides = rides;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật danh sách chuyến xe')),
        );
      }
    } catch (e) {
      print('❌ Error refreshing rides: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật danh sách: $e')),
        );
      }
    }
  }

  Future<void> _searchRides() async {
    if (_departure.isEmpty && _destination.isEmpty && _departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập ít nhất một điều kiện tìm kiếm'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final rides = await _rideService.searchRides(
        departure: _departure,
        destination: _destination,
        startTime: _departureDate,
        passengerCount: _passengerCount,
      );

      setState(() {
        _availableRides = rides;
        _isLoading = false;
      });

      if (rides.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy chuyến xe phù hợp')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tìm thấy ${rides.length} chuyến đi phù hợp')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tìm kiếm: $e')),
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
                await _authController.logout(context);
                // NavigationHelper sẽ xử lý việc điều hướng
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

  void _navigateToScreen(BuildContext context, String routeName) {
    // Sử dụng TabNavigator nếu có thể truy cập được
    final tabNavigator = TabNavigator.of(context);

    switch (routeName) {
      case DriverRoutes.bookings:
        if (tabNavigator != null) {
          // Chuyển đến tab 1 (Đặt chỗ)
          tabNavigator.navigateToTab(1);
          // Đóng drawer nếu đang mở
          Navigator.maybePop(context);
        } else {
          // Fallback to normal navigation
          Navigator.pushNamed(context, routeName);
        }
        break;
      case PassengerRoutes.profile:
        if (tabNavigator != null) {
          // Chuyển đến tab 3 (Cá nhân)
          tabNavigator.navigateToTab(3);
          // Đóng drawer nếu đang mở
          Navigator.maybePop(context);
        } else {
          Navigator.pushNamed(context, routeName);
        }
        break;
      case AppRoute.chatList:
        if (tabNavigator != null) {
          // Chuyển đến tab 2 (Liên hệ)
          tabNavigator.navigateToTab(2);
          // Đóng drawer nếu đang mở
          Navigator.maybePop(context);
        } else {
          Navigator.pushNamed(context, routeName);
        }
        break;
      default:
        Navigator.pushNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground1(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF00AEEF),
          title: const Text('Trang chủ'),
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(_userProfile?.fullName ?? 'Hành khách'),
                accountEmail: Text(_userProfile?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _userProfile?.avatarUrl != null
                          ? NetworkImage(_userProfile!.avatarUrl!)
                          : null,
                  child:
                      _userProfile?.avatarUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF00AEEF),
                          )
                          : null,
                ),
                decoration: const BoxDecoration(color: Color(0xFF00AEEF)),
              ),
              // Thêm menu items
              ListTile(
                leading: const Icon(Icons.home, color: Color(0xFF00AEEF)),
                title: const Text('Trang chủ'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToScreen(context, PassengerRoutes.home);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFF00AEEF)),
                title: const Text('Chuyến đi của tôi'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToScreen(context, DriverRoutes.bookings);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF00AEEF)),
                title: const Text('Tin nhắn'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToScreen(context, AppRoute.chatList);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF00AEEF)),
                title: const Text('Thông tin cá nhân'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToScreen(context, PassengerRoutes.profile);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
        body:
            _isLoading && _availableRides.isEmpty
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : RefreshIndicator(
                  onRefresh: _refreshRides,
                  color: const Color(0xFF00AEEF),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thẻ chào mừng với thiết kế mới
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00AEEF), Color(0xFF0078A8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 25,
                                    backgroundImage:
                                        _userProfile?.avatarUrl != null
                                            ? NetworkImage(
                                              _userProfile!.avatarUrl!,
                                            )
                                            : null,
                                    child:
                                        _userProfile?.avatarUrl == null
                                            ? const Icon(
                                              Icons.person,
                                              size: 30,
                                              color: Color(0xFF00AEEF),
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xin chào, ${_userProfile?.fullName ?? 'Hành khách'}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Text(
                                          'Chào mừng bạn đến với ShareXE',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Form tìm kiếm trực tiếp trên màn hình (không dùng dialog)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          color: Colors.white,
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tìm chuyến đi phù hợp',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00AEEF),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                LocationPicker(
                                  title: 'Điểm đi',
                                  icon: Icons.circle_outlined,
                                  hintText: 'Xuất phát từ',
                                  onLocationSelected: (location) {
                                    setState(() {
                                      _departure = location;
                                    });
                                  },
                                ),
                                const Divider(height: 1),
                                LocationPicker(
                                  title: 'Điểm đến',
                                  icon: Icons.location_on_outlined,
                                  hintText: 'Điểm đến',
                                  onLocationSelected: (location) {
                                    setState(() {
                                      _destination = location;
                                    });
                                  },
                                ),
                                const Divider(height: 1),
                                DatePickerField(
                                  icon: Icons.access_time,
                                  hintText: 'Thời gian xuất phát',
                                  onDateSelected: (date) {
                                    setState(() {
                                      _departureDate = date;
                                    });
                                  },
                                ),
                                const Divider(height: 1),
                                PassengerCounter(
                                  icon: Icons.people_outline,
                                  hintText: 'Số lượng',
                                  onCountChanged: (count) {
                                    setState(() {
                                      _passengerCount = count;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _searchRides,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF002D62),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Tìm chuyến', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Thêm nút "Chuyến đi của tôi"
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            color: Colors.white,
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  DriverRoutes.bookings,
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00AEEF).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.history,
                                        color: Color(0xFF00AEEF),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Chuyến đi của tôi',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF00AEEF),
                                            ),
                                          ),
                                          Text(
                                            'Xem các chuyến đi đã đặt và lịch sử',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Color(0xFF00AEEF),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Phần danh sách chuyến đi với thiết kế mới
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF00AEEF,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.directions_car_filled,
                                          color: Color(0xFF00AEEF),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Chuyến đi gần đây',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00AEEF),
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: _isRefreshing 
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF00AEEF),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.refresh,
                                            color: Color(0xFF00AEEF),
                                          ),
                                    onPressed: _isRefreshing ? null : _refreshRides,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              if (_availableRides.isEmpty && !_isLoading)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.car_crash,
                                        size: 40,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Không có chuyến đi nào',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      ElevatedButton(
                                        onPressed: () {
                                          _searchRides();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00AEEF),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: const Text('Tìm chuyến đi'),
                                      ),
                                    ],
                                  ),
                                )
                              else if (_isLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 30),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF00AEEF),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _availableRides.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final ride = _availableRides[index];
                                    return RideCard(
                                      ride: ride,
                                      onTap: () async {
                                        // Load ride details when tapped
                                        final rideDetails = await _rideService.getRideDetails(ride.id);

                                        if (mounted && rideDetails != null) {
                                          // Navigate to ride details screen and expect a result
                                          final result = await Navigator.pushNamed(
                                            context,
                                            AppRoute.rideDetails,
                                            arguments: rideDetails,
                                          );
                                          
                                          // Refresh rides list if booking was canceled
                                          if (result == true && mounted) {
                                            print('🔄 Booking đã hủy, làm mới danh sách chuyến đi');
                                            _loadAvailableRides();
                                          }
                                        }
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  // Widget để tạo nút hành động trong thẻ chào mừng
  Widget _buildActionButtonNew(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 