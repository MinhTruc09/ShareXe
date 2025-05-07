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
  
  List<Booking> _pendingBookings = [];
  bool _isLoading = false;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
    _loadPendingBookings();
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

  Future<void> _loadPendingBookings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use the booking service to get real pending bookings
      final bookings = await _bookingService.getDriverPendingBookings();
      
      setState(() {
        _pendingBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pending bookings: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải yêu cầu: $e')),
        );
      }
    }
  }
  
  Future<void> _acceptBooking(Booking booking) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Call API to accept booking
      final success = await _notificationService.acceptBooking(booking.id);
      
      if (success) {
        // Update local state
        setState(() {
          _pendingBookings = _pendingBookings.where((b) => b.id != booking.id).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chấp nhận yêu cầu thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi chấp nhận yêu cầu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _rejectBooking(Booking booking) async {
    // In a real implementation, you'd call an API to reject
    setState(() {
      _pendingBookings = _pendingBookings.where((b) => b.id != booking.id).toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã từ chối yêu cầu')),
    );
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

  @override
  Widget build(BuildContext context) {
    return SharexeBackground1(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF002D72),
          title: const Text('Trang chủ tài xế'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
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
                  backgroundImage: _userProfile?.avatarUrl != null 
                    ? NetworkImage(_userProfile!.avatarUrl!)
                    : null,
                  child: _userProfile?.avatarUrl == null 
                    ? const Icon(Icons.person, size: 40, color: Colors.blue)
                    : null,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF002D72),
                ),
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadPendingBookings,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chào mừng bạn đến với ShareXE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Bạn đã đăng nhập với tư cách tài xế. Bạn có thể quản lý các chuyến đi và xem yêu cầu từ khách hàng.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Các chuyến đi sắp tới',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 0, // Sẽ được cập nhật khi có dữ liệu thực tế
                        itemBuilder: (context, index) {
                          return const Card(
                            margin: EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text('Chuyến đi #...'),
                              subtitle: Text('Chưa có dữ liệu'),
                              trailing: Icon(Icons.arrow_forward),
                            ),
                          );
                        },
                      ),
                      if (0 == 0) // Nếu không có chuyến đi nào
                        const Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Chưa có chuyến đi nào'),
                          ),
                        ),
                      const SizedBox(height: 20),
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
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _loadPendingBookings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pendingBookings.length,
                        itemBuilder: (context, index) {
                          final booking = _pendingBookings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Yêu cầu #${booking.id}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(booking.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Hành khách: ${booking.passengerName}'),
                                  Text('Số ghế: ${booking.seatsBooked}'),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                                        onPressed: () => _rejectBooking(booking),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check),
                                        label: const Text('Chấp nhận'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
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
                      ),
                      if (_pendingBookings.isEmpty) // Nếu không có yêu cầu nào
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
              ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 0, // Home tab
          onTap: (index) {
            if (index == 3) { // Profile tab
              Navigator.pushNamed(context, AppRoute.profileDriver);
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
} 