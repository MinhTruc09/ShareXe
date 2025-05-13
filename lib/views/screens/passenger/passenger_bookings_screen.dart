import 'package:flutter/material.dart';
import 'package:sharexe/services/booking_service.dart';
import 'package:sharexe/models/booking.dart';
import 'package:sharexe/app_route.dart';
import 'package:sharexe/views/widgets/sharexe_background1.dart';
import 'package:intl/intl.dart';
import 'package:sharexe/services/ride_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sharexe/models/ride.dart';
import 'package:sharexe/services/notification_service.dart';
import 'package:sharexe/views/screens/common/ride_details.dart';
import 'package:sharexe/views/widgets/ride_card.dart';
import 'package:sharexe/utils/app_config.dart';
import 'package:sharexe/views/screens/passenger/passenger_main_screen.dart';

class PassengerBookingsScreen extends StatefulWidget {
  const PassengerBookingsScreen({Key? key}) : super(key: key);

  @override
  _PassengerBookingsScreenState createState() => _PassengerBookingsScreenState();
}

class _PassengerBookingsScreenState extends State<PassengerBookingsScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  final RideService _rideService = RideService();
  
  late TabController _tabController;
  List<BookingDTO> _upcomingBookings = [];
  List<BookingDTO> _inProgressBookings = []; // Chuyến đi đang diễn ra
  List<BookingDTO> _completedBookings = [];
  List<BookingDTO> _cancelledOrExpiredBookings = []; // Chuyến đã hủy hoặc hết hạn
  bool _isLoading = false;

  // Map to track the expanded state of each booking card
  final Map<int, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Thêm tab cho chuyến đi đang diễn ra
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Kiểm tra xem booking có hết hạn hay không (quá ngày đi mà chưa được chấp nhận)
  bool _isBookingExpired(BookingDTO booking) {
    final DateTime now = DateTime.now();
    final DateTime startTime = booking.startTime;
    
    // Nếu startTime đã qua và booking vẫn PENDING, thì coi như đã hết hạn
    return now.isAfter(startTime) && booking.status == 'PENDING';
  }

  // Phân loại bookings theo trạng thái
  Future<void> _loadBookings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      print('🔍 Đang tải danh sách bookings của hành khách...');

      // Gọi API để lấy danh sách bookings
      final bookings = await _bookingService.getPassengerBookingsDTO();
      
      if (bookings.isEmpty) {
        print('ℹ️ Không có bookings nào được tìm thấy');
      } else {
        print('✅ Đã tải ${bookings.length} bookings');
      }

      // Phân loại bookings
      final List<BookingDTO> upcoming = [];
      final List<BookingDTO> inProgress = [];
      final List<BookingDTO> completed = [];
      final List<BookingDTO> cancelledOrExpired = [];

      for (var booking in bookings) {
        print('Phân loại booking #${booking.id}: ${booking.status}, ngày đi: ${booking.startTime}');
        final status = booking.status.toUpperCase();
        final now = DateTime.now();
        final startTime = booking.startTime;
        
        // Phân loại theo trạng thái
        if (status == 'CANCELLED' || status == 'REJECTED' || _isBookingExpired(booking)) {
          // Chuyến đã hủy hoặc từ chối hoặc đã hết hạn
          cancelledOrExpired.add(booking);
        } 
        else if (status == 'COMPLETED' || status == 'PASSENGER_CONFIRMED' || status == 'DRIVER_CONFIRMED') {
          // Các trạng thái hoàn thành: đã xác nhận từ cả hai phía hoặc hoàn thành
          completed.add(booking);
        }
        else if (status == 'IN_PROGRESS') {
          // Trạng thái đang diễn ra
          inProgress.add(booking);
        }
        else if (status == 'ACCEPTED') {
          // Kiểm tra xem chuyến đi đã đến thời điểm khởi hành hay chưa
          if (now.isAfter(startTime)) {
            // Đã đến giờ khởi hành, chuyến đang diễn ra
            inProgress.add(booking);
          } else {
            // Chưa đến giờ khởi hành, chuyến sắp tới
            upcoming.add(booking);
          }
        } 
        else if (status == 'PENDING') {
          // Chuyến chờ duyệt
          upcoming.add(booking);
        }
        else {
          // Các trạng thái khác chưa xác định, tạm thời đưa vào upcoming
          print('⚠️ Trạng thái không xác định: $status cho booking #${booking.id}');
          upcoming.add(booking);
        }
      }

      if (mounted) {
        setState(() {
          _upcomingBookings = upcoming;
          _inProgressBookings = inProgress; 
          _completedBookings = completed;
          _cancelledOrExpiredBookings = cancelledOrExpired;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Lỗi khi tải bookings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Xử lý khi người dùng hủy booking
  Future<void> _handleCancelBooking(BookingDTO booking) async {
    // Hiển thị dialog xác nhận
    bool? confirmCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy booking này không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Có, hủy booking'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmCancel != true) return;

    // Hiển thị loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API để hủy booking
      final success = await _bookingService.cancelBooking(booking.rideId);

      if (success) {
        // Gửi thông báo cho tài xế
        try {
          // Sử dụng sendNotification thay thế vì Booking không có đủ các trường
          await _notificationService.sendNotification(
            'Booking đã bị hủy',
            'Hành khách ${booking.passengerName} đã hủy booking cho chuyến đi từ ${booking.departure} đến ${booking.destination}',
            AppConfig.NOTIFICATION_BOOKING_CANCELLED,
            {
              'bookingId': booking.id,
              'rideId': booking.rideId,
            },
            recipientEmail: booking.driverEmail
          );
        } catch (e) {
          print('❌ Lỗi khi gửi thông báo hủy booking: $e');
          // Không dừng quy trình vì đây không phải lỗi chính
        }

        // Làm mới danh sách bookings
        await _loadBookings();
        
        // Thông báo cho PassengerMainScreen để làm mới danh sách chuyến đi
        try {
          // Lấy TabNavigator instance từ context
          final tabNavigator = TabNavigator.of(context);
          if (tabNavigator != null) {
            print('✅ Tìm thấy TabNavigator, yêu cầu làm mới danh sách chuyến đi');
            tabNavigator.refreshHomeTab();
          } else {
            print('⚠️ Không tìm thấy TabNavigator để làm mới danh sách');
            // Thử cách khác - navigate về màn hình chính
            Navigator.pushNamedAndRemoveUntil(
              context,
              PassengerRoutes.home, 
              (route) => false
            );
          }
        } catch (e) {
          print('⚠️ Lỗi khi làm mới danh sách chuyến đi: $e');
          // Không dừng quy trình vì đây không phải lỗi chính
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy booking thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể hủy booking. Vui lòng thử lại sau.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi khi hủy booking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Xác nhận hoàn thành chuyến đi
  Future<void> _confirmRideCompletion(BookingDTO booking) async {
    // Hiển thị dialog xác nhận
    bool? confirmComplete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text(
          'Bạn xác nhận đã hoàn thành chuyến đi này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận hoàn thành'),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ],
      ),
    );

    if (confirmComplete != true) return;

    // Hiển thị loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API để xác nhận hoàn thành chuyến đi
      final success = await _rideService.passengerConfirmCompletion(booking.rideId);

      if (success) {
        // Gửi thông báo cho tài xế
        await _notificationService.sendNotification(
          'Hành khách đã xác nhận hoàn thành',
          'Hành khách ${booking.passengerName} đã xác nhận hoàn thành chuyến đi.',
          'PASSENGER_CONFIRMED',
          {
            'bookingId': booking.id,
            'rideId': booking.rideId,
          },
          recipientEmail: booking.driverEmail,
        );

        // Làm mới danh sách bookings
        await _loadBookings();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xác nhận hoàn thành chuyến đi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xác nhận hoàn thành. Vui lòng thử lại sau.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi khi xác nhận hoàn thành: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Xem chi tiết booking
  void _viewBookingDetails(BookingDTO booking) async {
    // Tạo đối tượng Ride từ thông tin trong BookingDTO
    final ride = Ride(
      id: booking.rideId,
      driverName: booking.driverName,
      driverEmail: booking.driverEmail,
      departure: booking.departure,
      destination: booking.destination,
      startTime: booking.startTime.toIso8601String(),
      pricePerSeat: booking.pricePerSeat,
      availableSeats: booking.availableSeats,
      totalSeat: booking.totalSeats,
      status: booking.rideStatus,
    );

    // Convert BookingDTO to Booking for compatibility
    final bookingObj = booking.toBooking();

    // Navigate to RideDetailsScreen with both ride and booking
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailScreen(
          ride: ride,
        ),
      ),
    );

    // Refresh bookings list after returning
    _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch sử Booking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Đang đi'),
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: SharexeBackground1(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadBookings,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Sắp tới
                    _buildBookingsList(_upcomingBookings, true, false),
                    
                    // Đang đi
                    _buildBookingsList(_inProgressBookings, false, true),
                    
                    // Hoàn thành
                    _buildBookingsList(_completedBookings, false, false),
                    
                    // Đã hủy
                    _buildBookingsList(_cancelledOrExpiredBookings, false, false),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBookingsList(List<BookingDTO> bookings, bool showCancelButton, bool showConfirmButton) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upcoming, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              showCancelButton 
                  ? 'Không có chuyến đi nào sắp tới' 
                  : showConfirmButton 
                      ? 'Không có chuyến đi nào đang diễn ra'
                      : 'Không có lịch sử chuyến đi',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        bool isExpanded = _expandedState[booking.id] ?? false;
        
        // Tạo Ride object từ BookingDTO
        final ride = Ride(
          id: booking.rideId,
          driverName: booking.driverName,
          driverEmail: booking.driverEmail,
          departure: booking.departure,
          destination: booking.destination,
          startTime: booking.startTime.toIso8601String(),
          pricePerSeat: booking.pricePerSeat,
          availableSeats: booking.availableSeats,
          totalSeat: booking.totalSeats,
          status: booking.rideStatus,
        );
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: InkWell(
            onTap: () {
              _viewBookingDetails(booking);
            },
            child: Column(
              children: [
                // Use the updated RideCard
                RideCard(
                  ride: ride,
                  bookingDTO: booking,
                  showFavorite: false,
                  onTap: () {
                    _viewBookingDetails(booking);
                  },
                  onConfirmComplete: showConfirmButton ? 
                    () => _confirmRideCompletion(booking) : null,
                ),
                
                // Cancel button if needed
                if (showCancelButton)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          'Hủy booking',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => _handleCancelBooking(booking),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 