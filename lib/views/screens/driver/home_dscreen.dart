import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/controllers/auth_controller.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/models/booking.dart';
import 'package:sharexe/services/notification_service.dart';
import 'package:sharexe/services/booking_service.dart';
import 'package:intl/intl.dart';
import '../../../services/profile_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/notification_model.dart';
import '../../../services/auth_manager.dart';
import 'package:flutter/foundation.dart';
import '../../../models/ride.dart';
import '../../../services/ride_service.dart';

class HomeDscreen extends StatefulWidget {
  const HomeDscreen({super.key});

  @override
  State<HomeDscreen> createState() => _HomeDscreenState();
}

class _HomeDscreenState extends State<HomeDscreen> {
  late AuthController _authController;
  final NotificationService _notificationService = NotificationService();
  final BookingService _bookingService = BookingService();
  final ProfileService _profileService = ProfileService();
  final AuthManager _authManager = AuthManager();
  final RideService _rideService = RideService();

  List<Booking> _pendingBookings = [];
  List<Ride> _driverRides = [];
  bool _isLoading = false;
  bool _isOffline = false;
  UserProfile? _userProfile;
  int _activeRideCount = 0;
  int _totalCompletedRides = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
    _loadPendingBookings();
    _loadUserProfile();
    _loadDriverStats();
    _loadDriverRides();

    // Refresh the rides again after a small delay to make sure API is ready
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadDriverRides();
      }
    });
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
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
    }
  }

  Future<void> _loadDriverStats() async {
    // Nếu chưa có dữ liệu chuyến đi, sử dụng giá trị mặc định
    if (_driverRides.isEmpty) {
      setState(() {
        _activeRideCount = 1; // Giả sử có ít nhất một chuyến đi hoạt động
        _totalCompletedRides = 0;
        _totalEarnings = 0;
      });
    } else {
      // Cập nhật thống kê dựa trên dữ liệu thực tế
      setState(() {
        _activeRideCount =
            _driverRides.where((ride) => ride.status == 'ACTIVE').length;
        _totalCompletedRides =
            _driverRides.where((ride) => ride.status == 'COMPLETED').length;

        // Tính tổng thu nhập (chỉ từ các chuyến đã hoàn thành)
        _totalEarnings = _driverRides
            .where((ride) => ride.status == 'COMPLETED')
            .fold(
              0,
              (sum, ride) => sum + (ride.pricePerSeat ?? 0) * ride.totalSeat,
            );
      });
    }
  }

  Future<void> _loadDriverRides() async {
    try {
      print('🚗 Đang tải danh sách chuyến đi của tài xế...');
      final rides = await _rideService.getDriverRides();

      print('🚗 Số chuyến đi đã tải: ${rides.length}');
      if (rides.isNotEmpty) {
        print(
          '🚗 Chuyến đi đầu tiên: ${rides[0].departure} → ${rides[0].destination}',
        );
      }

      setState(() {
        _driverRides = rides;

        // Cập nhật thống kê dựa trên dữ liệu thực tế
        if (rides.isNotEmpty) {
          _activeRideCount =
              rides.where((ride) => ride.status == 'ACTIVE').length;
          _totalCompletedRides =
              rides.where((ride) => ride.status == 'COMPLETED').length;

          // Tính tổng thu nhập (chỉ từ các chuyến đã hoàn thành)
          _totalEarnings = rides
              .where((ride) => ride.status == 'COMPLETED')
              .fold(
                0,
                (sum, ride) => sum + (ride.pricePerSeat ?? 0) * ride.totalSeat,
              );
        }
      });

      print('✅ Đã tải ${rides.length} chuyến đi của tài xế');
      print(
        '✅ Thống kê: $_activeRideCount chuyến đang hoạt động, $_totalCompletedRides chuyến đã hoàn thành',
      );
    } catch (e) {
      print('❌ Lỗi khi tải danh sách chuyến đi: $e');

      // Hiển thị thông báo lỗi kết nối nếu cần
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection timed out')) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  Future<void> _loadPendingBookings() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
    });

    try {
      final bookings = await _bookingService.fetchPendingBookingsForDriver();
      setState(() {
        _pendingBookings = bookings;
      });
    } catch (e) {
      print('❌ Lỗi khi lấy danh sách đặt chỗ đang chờ: $e');

      // Hiển thị thông báo lỗi kết nối
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Connection timed out')) {
        setState(() {
          _isOffline = true;
        });
        _showConnectionErrorSnackbar();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showConnectionErrorSnackbar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Không thể kết nối tới máy chủ. Đang hiển thị dữ liệu ngoại tuyến.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: _loadPendingBookings,
        ),
      ),
    );
  }

  // Widget hiển thị trạng thái kết nối
  Widget _buildConnectionStatus() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.red.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ứng dụng đang hoạt động ở chế độ ngoại tuyến. Một số tính năng có thể không khả dụng.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            ElevatedButton(
              onPressed: _loadPendingBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptBooking(Booking booking) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Cập nhật trạng thái booking trong Firebase để theo dõi realtime
      await _notificationService.updateBookingStatus(booking.id, "APPROVED");

      // Gọi API để chấp nhận booking
      final success = await _notificationService.acceptBooking(booking.id);

      if (success) {
        // Cập nhật trạng thái trong giao diện
        setState(() {
          _pendingBookings =
              _pendingBookings.where((b) => b.id != booking.id).toList();
        });

        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chấp nhận yêu cầu thành công')),
          );
        }

        // Tạo thông báo cho hành khách
        try {
          // Sử dụng tên của hành khách từ booking để gửi thông báo
          if (kDebugMode) {
            print('Gửi thông báo tới: ${booking.passengerName}');
          }

          await _notificationService.showLocalNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch,
              userEmail:
                  booking
                      .passengerName, // Dùng passengerName vì không có passengerEmail
              title: 'Đặt chỗ đã được chấp nhận',
              content:
                  'Tài xế đã chấp nhận đặt chỗ của bạn cho chuyến đi #${booking.rideId}',
              type: 'booking_accepted',
              read: false,
              referenceId: booking.id,
              createdAt: DateTime.now(),
            ),
          );

          if (kDebugMode) {
            print('Đã gửi thông báo thành công');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Lỗi khi hiển thị thông báo: $e');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Có lỗi xảy ra khi chấp nhận yêu cầu'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    // In a real implementation, you'd call an API to reject
    setState(() {
      _pendingBookings =
          _pendingBookings.where((b) => b.id != booking.id).toList();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã từ chối yêu cầu')));
  }

  void _logout() async {
    await _authController.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoute.role);
    }
  }

  String _formatTime(String timeString) {
    try {
      final dateTime = DateTime.parse(timeString);
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return timeString;
    }
  }

  String _formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatCurrency.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground1(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF002D72),
          title: const Text('Trang chủ tài xế'),
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(_userProfile?.fullName ?? 'Tài xế'),
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
                            color: Colors.blue,
                          )
                          : null,
                ),
                decoration: const BoxDecoration(color: Color(0xFF002D72)),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Hồ sơ'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoute.profileDriver);
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_car),
                title: const Text('Chuyến đi của tôi'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to my rides screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Tin nhắn'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoute.chatList);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Cài đặt'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to settings screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Trợ giúp'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to help screen
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: _logout,
              ),
            ],
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _loadPendingBookings(),
                      _loadDriverRides(),
                      _loadUserProfile(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thẻ chào mừng
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xin chào, ${_userProfile?.fullName ?? 'Tài xế'}!',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Chào mừng bạn trở lại với ShareXE. Quản lý chuyến đi của bạn và kiếm thêm thu nhập.',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Hiển thị thông báo kết nối nếu offline
                        if (_isOffline) _buildConnectionStatus(),

                        const SizedBox(height: 16),

                        // Nút đăng chuyến đi
                        _buildCreateRideButton(),

                        const SizedBox(height: 20),

                        // Dashboard thống kê
                        _buildStatsDashboard(),

                        const SizedBox(height: 20),

                        // Các chuyến đi sắp tới
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Các chuyến đi sắp tới',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              onPressed: _loadPendingBookings,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildUpcomingRides(),

                        const SizedBox(height: 20),

                        // Yêu cầu chuyến đi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Yêu cầu chuyến đi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Làm mới',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: _loadPendingBookings,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildPendingBookings(),
                      ],
                    ),
                  ),
                ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 0, // Home tab
          onTap: (index) {
            if (index == 3) {
              // Profile tab
              Navigator.pushNamed(context, AppRoute.profileDriver);
            } else if (index == 2) {
              // Chat tab
              Navigator.pushNamed(context, AppRoute.chatList);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              label: 'Chuyến đi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Liên hệ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRideButton() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF00AEEF),
      elevation: 4,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(context, AppRoute.createRide);
          // Tải lại danh sách chuyến đi sau khi tạo thành công
          _loadDriverRides();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Row(
            children: [
              Icon(
                Icons.add_circle,
                size: 48,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đăng Chuyến Đi Mới',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tạo chuyến đi mới và kiếm thêm thu nhập',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsDashboard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF002D72),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thống Kê Hoạt Động',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Chuyến Đi\nHiện Tại',
                  _activeRideCount.toString(),
                  Icons.directions_car,
                  Colors.green.shade300,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Chuyến Đi\nĐã Hoàn Thành',
                  _totalCompletedRides.toString(),
                  Icons.check_circle,
                  Colors.blue.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Tổng Thu Nhập',
            _formatCurrency(_totalEarnings),
            Icons.account_balance_wallet,
            Colors.orange.shade300,
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRides() {
    // Kiểm tra nếu không có chuyến đi nào
    if (_driverRides.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 16),
              Text(
                'Bạn chưa có chuyến đi nào sắp tới',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Hiển thị danh sách các chuyến đi của tài xế
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _driverRides.length,
      itemBuilder: (context, index) {
        final ride = _driverRides[index];

        // Định dạng thời gian
        String formattedTime = _formatTime(ride.startTime);

        // Tạo biểu tượng trạng thái
        Widget statusIcon;
        Color statusColor;

        switch (ride.status) {
          case 'ACTIVE':
            statusColor = Colors.green;
            statusIcon = const Icon(
              Icons.schedule,
              color: Colors.green,
              size: 16,
            );
            break;
          case 'COMPLETED':
            statusColor = Colors.blue;
            statusIcon = const Icon(
              Icons.check_circle,
              color: Colors.blue,
              size: 16,
            );
            break;
          case 'CANCELLED':
            statusColor = Colors.red;
            statusIcon = const Icon(Icons.cancel, color: Colors.red, size: 16);
            break;
          default:
            statusColor = Colors.orange;
            statusIcon = const Icon(
              Icons.help_outline,
              color: Colors.orange,
              size: 16,
            );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () {
              // TODO: Chuyển đến trang chi tiết chuyến đi
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề và trạng thái
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: Color(0xFF002D72),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${ride.departure} → ${ride.destination}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            statusIcon,
                            const SizedBox(width: 4),
                            Text(
                              ride.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Thông tin chi tiết
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(formattedTime, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.airline_seat_recline_normal,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.availableSeats}/${ride.totalSeat} ghế trống',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Giá và hành động
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ride.pricePerSeat != null
                            ? 'Giá: ${_formatCurrency(ride.pricePerSeat!)}/ghế'
                            : 'Giá: Liên hệ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002D72),
                        ),
                      ),

                      ride.status == 'ACTIVE'
                          ? OutlinedButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Quản lý'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF002D72),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: const BorderSide(color: Color(0xFF002D72)),
                            ),
                            onPressed: () {
                              // TODO: Navigate to ride management screen
                            },
                          )
                          : const SizedBox(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingBookings() {
    if (_pendingBookings.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 16),
              Text('Không có yêu cầu đặt chỗ mới'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingBookings.length,
      itemBuilder: (context, index) {
        final booking = _pendingBookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF002D72),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.passengerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Mã đặt chỗ: #${booking.id}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Chờ duyệt',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Số ghế: ${booking.seatsBooked}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Ngày đặt: ${_formatTime(booking.createdAt)}'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Từ chối',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        backgroundColor: Colors.red.withOpacity(0.1),
                      ),
                      onPressed: () => _rejectBooking(booking),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Chấp nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002D72),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _acceptBooking(booking),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
