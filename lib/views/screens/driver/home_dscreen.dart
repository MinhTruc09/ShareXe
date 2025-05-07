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
import '../../../models/driver_profile.dart';
import '../../../models/notification_model.dart';
import '../../../services/auth_manager.dart';
import '../../../services/driver_profile_service.dart';
import 'package:flutter/foundation.dart';
import '../../../services/ride_service.dart';
import '../../../models/ride.dart';
import 'post_ride_screen.dart';
import '../chat/chat_list_screen.dart';
import 'profile_screen.dart';

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
  final DriverProfileService _driverProfileService = DriverProfileService();

  List<Booking> _pendingBookings = [];
  List<Ride> _myRides = [];
  bool _isLoading = false;
  DriverProfile? _driverProfile;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
    _loadPendingBookings();
    _loadUserProfile();
    _loadMyRides();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _driverProfileService.getDriverProfile();

      if (profile != null) {
        setState(() {
          _driverProfile = profile;
        });
      }
    } catch (e) {
      print('Error loading driver profile: $e');
    }
  }

  Future<void> _loadMyRides() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // This would be replaced with actual API call to get driver's rides
      // For now, we'll use a mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isLoading = false;
        // Mock data for demonstration
        _myRides = [
          Ride(
            id: 1,
            availableSeats: 2,
            driverName: _driverProfile?.fullName ?? 'Tài xế',
            driverEmail: _driverProfile?.email ?? 'driver@example.com',
            departure: 'Long An',
            destination: 'Cần Thơ',
            startTime: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
            pricePerSeat: 900000,
            totalSeat: 2,
            status: 'ACTIVE',
          ),
        ];
      });
    } catch (e) {
      print('Error loading rides: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Implement loading of pending bookings
      // ...
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chấp nhận yêu cầu thành công')),
        );

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi chấp nhận yêu cầu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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

  Future<void> _logout() async {
    try {
      await _authController.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoute.role);
      }
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<void> _navigateToPostRide() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostRideScreen(),
      ),
    );
    
    if (result == true) {
      // Reload rides if a new ride was posted
      _loadMyRides();
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
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    return formatter.format(amount);
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const Center(child: Text('Chuyến đi của tôi'));
      case 2:
        return const ChatListScreen();
      case 3:
        return DriverProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return _isLoading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: () async {
            await _loadPendingBookings();
            await _loadMyRides();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Ride Card
                Card(
                  elevation: 4,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: InkWell(
                    onTap: _navigateToPostRide,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.add_circle, color: Colors.blue.shade700, size: 40),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Đăng chuyến đi mới',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002D72),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 100,
                              color: Colors.blue.shade50,
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, color: Color(0xFF002D72), size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Xuất phát từ'),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, color: Color(0xFF002D72), size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Điểm đến'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  VerticalDivider(color: Colors.blue.shade200, thickness: 1),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, color: Color(0xFF002D72), size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Thời gian xuất phát'),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.airline_seat_recline_normal, color: Color(0xFF002D72), size: 20),
                                            const SizedBox(width: 8),
                                            const Text('Số lượng'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _navigateToPostRide,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF002D72),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Đăng chuyến +',
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
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Chuyến đi hiện tại của bạn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002D72),
                  ),
                ),
                const SizedBox(height: 12),
                
                if (_myRides.isEmpty)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'Bạn chưa có chuyến đi nào',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _myRides.length,
                    itemBuilder: (context, index) {
                      final ride = _myRides[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Đang mở',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatCurrency(ride.pricePerSeat ?? 0),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF002D72),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Color(0xFF002D72)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ride.departure,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Container(
                                  height: 30,
                                  width: 2,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFF002D72)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ride.destination,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(ride.startTime),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.airline_seat_recline_normal, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${ride.availableSeats}/${ride.totalSeat} ghế',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // View ride details
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF002D72)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Chi tiết'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Edit ride
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF002D72),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Chỉnh sửa'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),
                
                // Pending bookings (existing code)
                const Text(
                  'Yêu cầu đặt xe đang chờ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002D72),
                  ),
                ),
                const SizedBox(height: 8),
                
                if (_pendingBookings.isEmpty)
                  const Card(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Chưa có yêu cầu nào'),
                    ),
                  ),
              ],
            ),
          ),
        );
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
                accountName: Text(_driverProfile?.fullName ?? 'Tài xế'),
                accountEmail: Text(_driverProfile?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _driverProfile?.avatarUrl != null
                          ? NetworkImage(_driverProfile!.avatarUrl!)
                          : null,
                  child:
                      _driverProfile?.avatarUrl == null
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
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Đăng chuyến mới'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToPostRide();
                },
              ),
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
        body: _buildBody(),
        floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
          onPressed: _navigateToPostRide,
          backgroundColor: const Color(0xFF002D72),
          child: const Icon(Icons.add),
        ) : null,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
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
}
