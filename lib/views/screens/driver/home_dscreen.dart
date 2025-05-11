import 'package:flutter/material.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:sharexe/services/auth_service.dart';
import 'package:sharexe/controllers/auth_controller.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/models/booking.dart';
import 'package:sharexe/models/ride.dart';
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
import '../../../utils/app_config.dart';
import '../../../utils/api_debug_helper.dart'; // Add this import
import '../../../utils/navigation_helper.dart'; // Thêm import NavigationHelper
import '../../../views/widgets/skeleton_loader.dart';

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
  final AppConfig _appConfig = AppConfig();
  bool _showDebugOptions = false;

  List<Booking> _pendingBookings = [];
  List<Ride> _availableRides = [];
  bool _isLoading = false;
  bool _isProcessingBooking = false;
  int _processingBookingId = -1;
  UserProfile? _userProfile;
  bool _isInitialLoad = true; // Track initial load to show skeleton

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
    _loadPendingBookings();
    _loadUserProfile();
    _loadAvailableRides();
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
    if (!_isInitialLoad) {
      setState(() {
        _isLoading = true;
      });
    }

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

      if (mounted) {
        setState(() {
          _pendingBookings = filteredBookings;
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      print('Error loading pending bookings: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
        
        // Show error to user
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

  Future<void> _loadAvailableRides() async {
    try {
      print('🔍 Fetching available rides for driver home screen...');
      
      // Sử dụng phương thức dành riêng cho tài xế
      final rides = await _rideService.getDriverAvailableRides();
      
      print('✅ Successfully fetched ${rides.length} rides for driver home screen');
      
      if (mounted) {
        setState(() {
          _availableRides = rides;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching rides for driver home screen: $e');
      if (mounted) {
        setState(() {
          _availableRides = [];
          _isInitialLoad = false;
        });
      }
    }
  }

  Future<void> _acceptBooking(Booking booking) async {
    // Lưu trữ dữ liệu booking hiện tại để phòng trường hợp lỗi API
    final Booking currentBooking = booking;
    
    try {
      // Hiển thị dialog xác nhận
      final bool? confirmResult = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Xác nhận duyệt yêu cầu'),
            content: const Text('Bạn có chắc chắn muốn duyệt yêu cầu đặt chỗ này không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Duyệt'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          );
        },
      );
      
      if (confirmResult != true) {
        return;
      }
      
      setState(() {
        _isProcessingBooking = true;
        _processingBookingId = booking.id;
        
        // Cập nhật UI trước để tránh mất dữ liệu nếu API gọi thất bại
        _pendingBookings = _pendingBookings.where((b) => b.id != booking.id).toList();
      });

      // Use DTO-based method to accept booking
      final success = await _bookingService.driverAcceptBookingDTO(booking.id);

      if (success) {
        // Cập nhật status trong Firebase nếu cần thiết
        try {
          await _notificationService.updateBookingStatus(booking.id, "APPROVED");
        } catch (e) {
          print('⚠️ Lỗi khi cập nhật trạng thái trên Firebase: $e');
          // Không dừng quy trình vì đây không phải lỗi chính
        }

        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Chấp nhận yêu cầu thành công',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
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
              userEmail: booking.passengerName, // Dùng passengerName vì không có passengerEmail
              title: 'Đặt chỗ đã được chấp nhận',
              content: 'Tài xế đã chấp nhận đặt chỗ của bạn cho chuyến đi #${booking.rideId}',
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
          // Không dừng quy trình vì đây không phải lỗi chính
        }
      } else {
        if (mounted) {
          // Có lỗi, cần tìm cách khôi phục dữ liệu lên UI
          setState(() {
            // Thêm lại booking vào danh sách chờ duyệt để không mất dữ liệu
            _pendingBookings.add(currentBooking);
          });
          
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
      }
    } catch (e) {
      if (mounted) {
        // Khôi phục dữ liệu nếu có lỗi
        setState(() {
          // Thêm lại booking vào danh sách chờ duyệt
          _pendingBookings.add(currentBooking);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingBooking = false;
          _processingBookingId = -1;
        });
      }
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

      // Use DTO-based method to reject booking
      final success = await _bookingService.driverRejectBookingDTO(booking.id);
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
                if (mounted) {
                  // NavigationHelper sẽ xử lý việc điều hướng
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

  String _formatTime(String timeString) {
    try {
      if (timeString.isEmpty) {
        return "N/A";
      }
      final dateTime = DateTime.parse(timeString);
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
      print('❌ Lỗi khi định dạng thời gian: $e, timeString: $timeString');
      return timeString.isNotEmpty ? timeString : "N/A";
    }
  }

  String _formatDateTime(String? dateTimeString) {
    try {
      if (dateTimeString == null || dateTimeString.isEmpty) {
        return "N/A";
      }
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
    } catch (e) {
      print('❌ Lỗi khi định dạng ngày giờ: $e, dateTimeString: $dateTimeString');
      return dateTimeString ?? "N/A";
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
      // Cập nhật phần xử lý cho AppRoute.createRide
      case AppRoute.createRide:
        // Đóng drawer nếu đang mở
        Navigator.maybePop(context);
        // Điều hướng đến trang tạo chuyến đi
        NavigationHelper.navigateToCreateRide(context);
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

  void _toggleDebugOptions() {
    setState(() {
      _showDebugOptions = !_showDebugOptions;
    });
    
    if (_showDebugOptions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bật chế độ debug')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tắt chế độ debug')),
      );
    }
  }

  void _openApiDebugPage() {
    // Use the ApiDebugHelper to show the API debug screen
    ApiDebugHelper().showApiDebugScreen(context);
  }

  void _updateApiUrl() {
    // Use the ApiDebugHelper to show the update API URL dialog
    ApiDebugHelper().showUpdateApiUrlDialog(
      context,
      onUpdated: () {
        // Reload data after URL update
        _loadPendingBookings();
        _loadAvailableRides();
        _loadUserProfile();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground1(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF002D72),
          title: const Text('Trang chủ tài xế'),
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
            // Add debug button with long press gesture
            GestureDetector(
              onLongPress: _toggleDebugOptions,
              child: IconButton(
                icon: Icon(
                  _showDebugOptions ? Icons.bug_report : Icons.home,
                  color: _showDebugOptions ? Colors.amber : Colors.white,
                ),
                onPressed: _showDebugOptions ? _openApiDebugPage : null,
              ),
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
                currentAccountPicture: _buildUserAvatar(),
                decoration: const BoxDecoration(color: Color(0xFF002D72)),
              ),
            ],
          ),
        ),
        body:
            _isLoading && !_isInitialLoad
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : RefreshIndicator(
                  onRefresh: () async {
                    await _loadPendingBookings();
                    await _loadAvailableRides();
                  },
                  color: const Color(0xFF002D72),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thẻ chào mừng với thiết kế mới
                        _buildWelcomeCard(),
                        
                        const SizedBox(height: 24),

                        // Phần yêu cầu chờ duyệt với thiết kế mới
                        _buildPendingBookingsSection(),

                        const SizedBox(height: 24),

                        // Thêm phần hiển thị chuyến đi có sẵn
                        _buildAvailableRidesSection(),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  // Build welcome card widget
  Widget _buildWelcomeCard() {
    if (_isInitialLoad) {
      // Skeleton welcome card
      return Container(
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
                const SkeletonLoader(
                  width: 50, 
                  height: 50, 
                  borderRadius: 25
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLoader(
                        width: 200,
                        height: 24,
                        borderRadius: 4,
                      ),
                      SizedBox(height: 6),
                      SkeletonLoader(
                        width: 160,
                        height: 14,
                        borderRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SkeletonLoader(
              width: 180,
              height: 16,
              borderRadius: 4,
            ),
            const SizedBox(height: 15),
            Row(
              children: const [
                Expanded(
                  child: SkeletonLoader(
                    height: 48,
                    borderRadius: 10,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SkeletonLoader(
                    height: 48,
                    borderRadius: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  
    return Container(
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
              _buildUserAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    // Sử dụng NavigationHelper để điều hướng đến trang tạo chuyến đi
                    NavigationHelper.navigateToCreateRide(context);
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
    );
  }
  
  // Build pending bookings section
  Widget _buildPendingBookingsSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00AEEF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
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

          if (_isInitialLoad)
            // Show skeleton items while loading
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => const BookingCardSkeleton(),
            )
          else if (_pendingBookings.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final booking = _pendingBookings[index];
                return InkWell(
                  onTap: () {
                    // Navigate to ride details screen to see booking details
                    _viewBookingDetails(booking);
                  },
                  child: _buildPendingBookingCard(booking),
                );
              },
            ),
        ],
      ),
    );
  }
  
  // Build a pending booking card - extracted to make the code more readable
  Widget _buildPendingBookingCard(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00AEEF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF002D72).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mã: #${booking.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF002D72),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatTime(booking.createdAt),
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
                backgroundColor: Color(0xFF00AEEF),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
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
          if (booking.departure != null && booking.destination != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00AEEF).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF002D72),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Điểm đi: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF002D72),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          booking.departure!,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
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
                        color: Color(0xFF002D72),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Điểm đến: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF002D72),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          booking.destination!,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (booking.startTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Color(0xFF002D72),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Thời gian: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF002D72),
                            ),
                          ),
                          Text(
                            _formatDateTime(booking.startTime),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  if (booking.pricePerSeat != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            size: 16,
                            color: Color(0xFF002D72),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Giá/ghế: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF002D72),
                            ),
                          ),
                          Text(
                            booking.pricePerSeat != null
                              ? NumberFormat.currency(
                                  locale: 'vi_VN',
                                  symbol: '₫',
                                ).format(booking.pricePerSeat)
                              : 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.deepOrange,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Nhấn để xem chi tiết',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF00AEEF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
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
                  onPressed: _isProcessingBooking &&
                          _processingBookingId == booking.id
                      ? null
                      : () => _rejectBooking(booking),
                  icon: _isProcessingBooking &&
                          _processingBookingId == booking.id
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.close, size: 18),
                  label: const Text('Từ chối'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessingBooking &&
                          _processingBookingId == booking.id
                      ? null
                      : () => _acceptBooking(booking),
                  icon: _isProcessingBooking &&
                          _processingBookingId == booking.id
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Chấp nhận'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D72),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build available rides section
  Widget _buildAvailableRidesSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002D72).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: Color(0xFF002D72),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Chuyến đi của tôi',
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
                onPressed: _loadAvailableRides,
              ),
            ],
          ),
          const SizedBox(height: 15),

          if (_isInitialLoad)
            // Show skeleton items while loading
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => const RideCardSkeleton(),
            )
          else if (_availableRides.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.no_transfer,
                    size: 40,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Bạn chưa có chuyến đi nào',
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
              itemCount: _availableRides.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ride = _availableRides[index];
                // Ẩn chuyến đi nếu hết ghế
                if (ride.availableSeats <= 0) {
                  return const SizedBox.shrink();
                }
                return _buildRideCard(ride);
              },
            ),
        ],
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

  // Thêm widget hiển thị thông tin chuyến đi dành cho tài xế
  Widget _buildRideCard(Ride ride) {
    // Update this line to handle date parsing more safely
    DateTime startDateTime;
    try {
      startDateTime = DateTime.parse(ride.startTime);
    } catch (e) {
      print('❌ Error parsing date from ride.startTime: ${ride.startTime}');
      startDateTime = DateTime.now();
    }
    
    final priceFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF002D72).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF002D72).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mã: #${ride.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF002D72),
                  ),
                ),
              ),
              _buildStatusBadge(ride.status),
            ],
          ),
          
          const SizedBox(height: 5),
          
          // Ngày và giờ xuất phát
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm dd/MM/yyyy').format(startDateTime),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Điểm đi
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AEEF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF00AEEF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Điểm đi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      ride.departure,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Đường kẻ dọc
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(
                color: Colors.grey[400],
                thickness: 2,
                width: 20,
              ),
            ),
          ),
          
          // Điểm đến
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF002D72).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF002D72),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Điểm đến',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      ride.destination,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          
          // Thông tin chuyến đi (giá, ghế, tình trạng)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_seat,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Còn ${ride.availableSeats} ghế',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    size: 16,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ride.pricePerSeat != null 
                      ? '${priceFormat.format(ride.pricePerSeat)}/ghế'
                      : 'Miễn phí',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          if (ride.driverEmail != null) 
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tài xế: ${ride.driverName ?? 'Chưa có thông tin'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 15),
          
          // Nút xem chi tiết chuyến đi (dành cho tài xế)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      DriverRoutes.rideDetails,
                      arguments: ride,
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Xem chi tiết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D72),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: ride.driverEmail == _userProfile?.email 
                    ? (ride.status.toUpperCase() == 'CANCELLED'
                        ? null // Disable button if ride is cancelled
                        : () {
                          // Nếu đây là chuyến đi của tài xế hiện tại
                          Navigator.pushNamed(
                            context,
                            DriverRoutes.createRide,
                            arguments: {
                              'id': ride.id,
                              'departure': ride.departure,
                              'destination': ride.destination,
                              'startTime': ride.startTime,
                              'totalSeat': ride.totalSeat,
                              'pricePerSeat': ride.pricePerSeat,
                              'status': ride.status,
                            },
                          );
                        })
                    : null, // Disable nút nếu không phải chuyến đi của tài xế này
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Chỉnh sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF002D72),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF002D72)),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'AVAILABLE':
        color = Colors.green;
        label = 'Đang mở';
        break;
      case 'CANCELLED':
      case 'CANCEL':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      case 'COMPLETED':
      case 'DONE':
      case 'FINISHED':
        color = Colors.blue;
        label = 'Hoàn thành';
        break;
      case 'PENDING':
        color = Colors.orange;
        label = 'Chờ xác nhận';
        break;
      case 'FULL':
        color = Colors.purple;
        label = 'Đã đầy';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    // No need to check if _userProfile is null before accessing avatarUrl
    if (_userProfile?.avatarUrl != null && _userProfile!.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(_userProfile!.avatarUrl!),
      );
    } else {
      return const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          size: 40,
          color: Colors.blue,
        ),
      );
    }
  }
}

class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({Key? key}) : super(key: key);

  @override
  _ApiDebugScreenState createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  final AppConfig _appConfig = AppConfig();
  final ApiDebugHelper _apiDebugHelper = ApiDebugHelper();
  final List<Map<String, dynamic>> _endpoints = ApiDebugHelper().debugEndpoints;
  
  String _connectionStatus = 'Chưa kiểm tra';
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    _testApiConnection();
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = 'Đang kiểm tra kết nối...';
    });

    try {
      final isWorking = await _appConfig.isNgrokUrlWorking();
      
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = isWorking
            ? 'Kết nối API thành công ✅'
            : 'Không thể kết nối đến API ❌';
      });
    } catch (e) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = 'Lỗi kiểm tra kết nối: $e';
      });
    }
  }
  
  void _updateApiUrl() {
    _apiDebugHelper.showUpdateApiUrlDialog(
      context,
      onUpdated: () {
        // After URL is updated, test the connection
        _testApiConnection();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D72),
        title: const Text('Kiểm tra kết nối API'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current API URL section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API URL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _appConfig.apiBaseUrl,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Full API URL: ${_appConfig.fullApiUrl}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Connection status
                    Row(
                      children: [
                        const Text('Trạng thái:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionStatus,
                            style: TextStyle(
                              color: _connectionStatus.contains('thành công')
                                  ? Colors.green
                                  : _connectionStatus.contains('kiểm tra')
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isTestingConnection)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _testApiConnection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Kiểm tra lại'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateApiUrl();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Thay đổi URL'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Các API Endpoint',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // List of available endpoints
            ...List.generate(_endpoints.length, (index) {
              final endpoint = _endpoints[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(endpoint['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        endpoint['endpoint'],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        endpoint['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Test endpoint: ${_appConfig.fullApiUrl}${endpoint['endpoint']}',
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
            // Troubleshooting section
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xử lý sự cố',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Kiểm tra ngrok URL có còn hoạt động không (thường hết hạn sau 2 giờ)',
                    ),
                    Text('2. Chạy lại ngrok trên máy local và cập nhật URL mới'),
                    Text('3. Kiểm tra backend API có đang chạy không'),
                    Text('4. Kiểm tra xác thực token còn hợp lệ không'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
