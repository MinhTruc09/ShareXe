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
import '../../../services/ride_service.dart';
import 'driver_main_screen.dart'; // Import TabNavigator từ driver_main_screen.dart

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
  bool _isLoading = false;
  bool _isProcessingBooking = false;
  int _processingBookingId = -1;
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

      // Lọc loại bỏ các booking thuộc chuyến đi đã bị hủy
      final filteredBookings = <Booking>[];

      for (var booking in bookings) {
        try {
          // Kiểm tra trạng thái của chuyến đi tương ứng
          final ride = await _rideService.getRideDetails(booking.rideId);

          // Chỉ giữ lại booking của chuyến đi còn hoạt động (không bị hủy)
          if (ride != null &&
              ride.status.toUpperCase() != 'CANCELLED' &&
              ride.status.toUpperCase() != 'CANCEL') {
            filteredBookings.add(booking);
          } else {
            print(
              '🚫 Bỏ qua booking #${booking.id} thuộc chuyến đi #${booking.rideId} đã hủy',
            );
          }
        } catch (e) {
          print(
            '❌ Lỗi kiểm tra trạng thái chuyến đi cho booking #${booking.id}: $e',
          );
        }
      }

      setState(() {
        _pendingBookings = filteredBookings;
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
          SnackBar(
            content: Text(
              'Không thể tải yêu cầu: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptBooking(Booking booking) async {
    try {
      setState(() {
        _isProcessingBooking = true;
        _processingBookingId = booking.id;
      });

      // Bằng dòng này - sử dụng booking service
      final success = await _bookingService.acceptBooking(booking.id);

      if (success) {
        // Cập nhật status trong Firebase nếu cần thiết
        await _notificationService.updateBookingStatus(booking.id, "APPROVED");

        // Cập nhật UI như bình thường
        setState(() {
          _pendingBookings =
              _pendingBookings.where((b) => b.id != booking.id).toList();
        });

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chấp nhận yêu cầu thành công',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
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
          const SnackBar(
            content: Text(
              'Có lỗi xảy ra khi chấp nhận yêu cầu',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessingBooking = false;
        _processingBookingId = -1;
      });
    }
  }

  Future<void> _rejectBooking(Booking booking) async {
    try {
      setState(() {
        _isProcessingBooking = true;
        _processingBookingId = booking.id;
      });

      // Thêm thông tin debug
      print('🔄 Bắt đầu từ chối booking: #${booking.id}');

      // Gọi API để từ chối yêu cầu
      final success = await _bookingService.rejectBooking(booking.id);
      print('📱 Kết quả từ chối booking: $success');

      if (success) {
        // Cập nhật UI khi thành công
        setState(() {
          _pendingBookings =
              _pendingBookings.where((b) => b.id != booking.id).toList();
        });

        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Đã từ chối yêu cầu thành công',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Hiển thị thông báo lỗi với nhiều thông tin hơn
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Không thể từ chối yêu cầu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vui lòng kiểm tra kết nối mạng và thử lại',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Thử lại',
                textColor: Colors.white,
                onPressed: () => _rejectBooking(booking),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi chi tiết khi từ chối booking: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _rejectBooking(booking),
            ),
          ),
        );
      }
    } finally {
      // Luôn reset trạng thái xử lý
      if (mounted) {
        setState(() {
          _isProcessingBooking = false;
          _processingBookingId = -1;
        });
      }
    }
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

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  void _navigateToScreen(BuildContext context, String routeName) {
    // Sử dụng TabNavigator nếu có thể truy cập được
    final tabNavigator = TabNavigator.of(context);

    switch (routeName) {
      case AppRoute.myRides:
        if (tabNavigator != null) {
          // Chuyển đến tab 1 (Chuyến đi)
          tabNavigator.navigateToTab(1);
          // Đóng drawer nếu đang mở
          Navigator.maybePop(context);
        } else {
          // Fallback to normal navigation
          Navigator.pushNamed(context, routeName);
        }
        break;
      case AppRoute.profileDriver:
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
      // Các trường hợp khác sử dụng navigateTo từ TabNavigator hoặc điều hướng thông thường
      case AppRoute.createRide:
        if (tabNavigator != null) {
          // Đóng drawer nếu đang mở
          Navigator.maybePop(context);
          // Sử dụng hàm navigateTo từ TabNavigator
          tabNavigator.navigateTo(context, routeName);
        } else {
          Navigator.pushNamed(context, routeName);
        }
        break;
      default:
        Navigator.pushNamed(context, routeName);
    }
  }

  Future<void> _viewBookingDetails(Booking booking) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tải thông tin chuyến đi...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Get the complete ride details
      final ride = await _rideService.getRideDetails(booking.rideId);

      if (ride != null && mounted) {
        // Navigate to ride details with the complete ride object
        Navigator.pushNamed(context, DriverRoutes.rideDetails, arguments: ride);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải thông tin chuyến đi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
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
            ],
          ),
        ),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : RefreshIndicator(
                  onRefresh: _loadPendingBookings,
                  color: const Color(0xFF002D72),
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
                              colors: [Color(0xFF002D72), Color(0xFF0052CC)],
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
                                              color: Color(0xFF002D72),
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
                                          'Xin chào, ${_userProfile?.fullName ?? 'Tài xế'}',
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
                              const SizedBox(height: 20),
                              const Text(
                                'Hôm nay bạn muốn làm gì?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildActionButtonNew(
                                      'Tạo chuyến đi',
                                      Icons.add_road,
                                      () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoute.createRide,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildActionButtonNew(
                                      'Chuyến đi',
                                      Icons.directions_car,
                                      () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoute.myRides,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Phần yêu cầu chờ duyệt với thiết kế mới
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
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
                                          Icons.notifications_active,
                                          color: Color(0xFF00AEEF),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Yêu cầu chờ duyệt',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF002D72),
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Color(0xFF00AEEF),
                                    ),
                                    onPressed: _loadPendingBookings,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              if (_pendingBookings.isEmpty)
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
                                        Icons.notifications_off_outlined,
                                        size: 40,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Không có yêu cầu chờ duyệt',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _pendingBookings.length,
                                  separatorBuilder:
                                      (context, index) =>
                                          const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final booking = _pendingBookings[index];
                                    return InkWell(
                                      onTap: () {
                                        // Navigate to ride details screen to see booking details
                                        _viewBookingDetails(booking);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF00AEEF,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF002D72,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Mã: #${booking.id}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color(0xFF002D72),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _formatTime(
                                                      booking.createdAt,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor: Color(
                                                    0xFF00AEEF,
                                                  ),
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      booking.passengerName,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Số ghế: ${booking.seatsBooked}',
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),

                                            // Thêm thông tin chi tiết chuyến đi
                                            if (booking.departure != null &&
                                                booking.destination != null)
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF00AEEF,
                                                    ).withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.location_on,
                                                          size: 16,
                                                          color: Color(
                                                            0xFF002D72,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        const Text(
                                                          'Điểm đi: ',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Color(
                                                              0xFF002D72,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            booking.departure!,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.location_on,
                                                          size: 16,
                                                          color: Color(
                                                            0xFF002D72,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        const Text(
                                                          'Điểm đến: ',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Color(
                                                              0xFF002D72,
                                                            ),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            booking
                                                                .destination!,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (booking.startTime !=
                                                        null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 4,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.access_time,
                                                              size: 16,
                                                              color: Color(
                                                                0xFF002D72,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            const Text(
                                                              'Thời gian: ',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                  0xFF002D72,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              _formatDateTime(
                                                                booking
                                                                    .startTime!,
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    if (booking.pricePerSeat !=
                                                        null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 4,
                                                            ),
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .monetization_on,
                                                              size: 16,
                                                              color: Color(
                                                                0xFF002D72,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            const Text(
                                                              'Giá/ghế: ',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                  0xFF002D72,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              NumberFormat.currency(
                                                                locale: 'vi_VN',
                                                                symbol: '₫',
                                                              ).format(
                                                                booking
                                                                    .pricePerSeat,
                                                              ),
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    Colors
                                                                        .deepOrange,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),

                                            // Add a divider and "View Details" indicator
                                            const Divider(height: 24),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const Text(
                                                  'Nhấn để xem chi tiết',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF00AEEF),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 14,
                                                  color: Color(0xFF00AEEF),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 15),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed:
                                                        _isProcessingBooking &&
                                                                _processingBookingId ==
                                                                    booking.id
                                                            ? null
                                                            : () =>
                                                                _rejectBooking(
                                                                  booking,
                                                                ),
                                                    icon:
                                                        _isProcessingBooking &&
                                                                _processingBookingId ==
                                                                    booking.id
                                                            ? const SizedBox(
                                                              width: 14,
                                                              height: 14,
                                                              child: CircularProgressIndicator(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                strokeWidth: 2,
                                                              ),
                                                            )
                                                            : const Icon(
                                                              Icons.close,
                                                              size: 18,
                                                            ),
                                                    label: const Text(
                                                      'Từ chối',
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.grey[300],
                                                      foregroundColor:
                                                          Colors.black87,
                                                      elevation: 0,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 10,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed:
                                                        _isProcessingBooking &&
                                                                _processingBookingId ==
                                                                    booking.id
                                                            ? null
                                                            : () =>
                                                                _acceptBooking(
                                                                  booking,
                                                                ),
                                                    icon:
                                                        _isProcessingBooking &&
                                                                _processingBookingId ==
                                                                    booking.id
                                                            ? const SizedBox(
                                                              width: 14,
                                                              height: 14,
                                                              child: CircularProgressIndicator(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                strokeWidth: 2,
                                                              ),
                                                            )
                                                            : const Icon(
                                                              Icons.check,
                                                              size: 18,
                                                            ),
                                                    label: const Text(
                                                      'Chấp nhận',
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF002D72,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 0,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 10,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
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

  // Hàm cũ giữ lại cho tương thích
  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return _buildActionButtonNew(label, icon, onTap);
  }
}
