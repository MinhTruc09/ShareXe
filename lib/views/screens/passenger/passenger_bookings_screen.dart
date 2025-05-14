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
import 'package:sharexe/views/widgets/booking_card.dart';
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
        else if (status == 'COMPLETED') {
          // Chỉ hiển thị COMPLETED trong tab hoàn thành
          completed.add(booking);
        }
        else if (status == 'IN_PROGRESS' || status == 'DRIVER_CONFIRMED' || status == 'PASSENGER_CONFIRMED') {
          // Trạng thái đang diễn ra: IN_PROGRESS, DRIVER_CONFIRMED, hoặc PASSENGER_CONFIRMED
          inProgress.add(booking);
        }
        else if (status == 'ACCEPTED' || status == 'APPROVED') {
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
          // Chuyến chờ duyệt -> sắp tới
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
                    // Sắp tới - hiển thị booking đã được duyệt nhưng chưa đến giờ khởi hành
                    _buildBookingList(_upcomingBookings, 'Sắp tới'),
                    
                    // Đang đi - hiển thị IN_PROGRESS và DRIVER_CONFIRMED
                    _buildBookingList(_inProgressBookings, 'Đang đi'),
                    
                    // Hoàn thành - chỉ hiển thị COMPLETED
                    _buildBookingList(_completedBookings, 'Hoàn thành'),
                    
                    // Đã hủy - forceDisableInteraction = true để vô hiệu hóa tương tác
                    _buildBookingList(_cancelledOrExpiredBookings, 'Đã hủy'),
                  ],
                ),
              ),
      ),
    );
  }

  // Hiển thị danh sách bookings
  Widget _buildBookingList(List<BookingDTO> bookings, String title) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Không có booking nào' + (title.isNotEmpty ? ' $title' : ''),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        itemCount: bookings.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingCard(
            booking: booking,
            onTap: () => _loadBookings(),
            showCancelButton: _canCancel(booking),
            onCancel: () => _handleCancelBooking(booking),
            onConfirmComplete: _canConfirmComplete(booking) 
                ? () => _handleConfirmCompletion(booking) 
                : null,
          );
        },
      ),
    );
  }

  bool _canCancel(BookingDTO booking) {
    // Chỉ cho phép hủy các booking có trạng thái PENDING hoặc ACCEPTED/APPROVED và chưa đến giờ khởi hành
    final status = booking.status.toUpperCase();
    final now = DateTime.now();
    return (status == 'PENDING' || status == 'ACCEPTED' || status == 'APPROVED') && 
           now.isBefore(booking.startTime);
  }

  bool _canConfirmComplete(BookingDTO booking) {
    // Xác định xem booking có thể được xác nhận hoàn thành không
    final status = booking.status.toUpperCase();
    final now = DateTime.now();
    
    // Chỉ cho phép xác nhận hoàn thành nếu:
    // - Trạng thái là DRIVER_CONFIRMED, hoặc
    // - Trạng thái là ACCEPTED/APPROVED/IN_PROGRESS và đã đến giờ khởi hành
    return (status == 'DRIVER_CONFIRMED') || 
           ((status == 'ACCEPTED' || status == 'APPROVED' || status == 'IN_PROGRESS') && 
            now.isAfter(booking.startTime));
  }

  Future<void> _handleConfirmCompletion(BookingDTO booking) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Hiển thị dialog xác nhận
      final bool? confirmResult = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Xác nhận hoàn thành'),
            content: const Text('Bạn xác nhận đã hoàn thành chuyến đi này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xác nhận'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          );
        },
      );
      
      if (confirmResult != true) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Gọi API để xác nhận hoàn thành 
      final result = await _rideService.passengerConfirmCompletion(booking.rideId);
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xác nhận hoàn thành chuyến đi thành công'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Gửi thông báo cho tài xế (nếu cần)
        try {
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
        } catch (e) {
          print('❌ Lỗi khi gửi thông báo: $e');
          // Không dừng quy trình vì đây không phải lỗi chính
        }
        
        // Làm mới danh sách bookings
        await _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xác nhận hoàn thành. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi xác nhận hoàn thành chuyến đi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 