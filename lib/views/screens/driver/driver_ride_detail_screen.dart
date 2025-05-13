import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/ride_service.dart';
import '../../../utils/app_config.dart';
import '../../widgets/ride_card.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../../widgets/sharexe_background2.dart';

class DriverRideDetailScreen extends StatefulWidget {
  final dynamic ride;

  const DriverRideDetailScreen({super.key, required this.ride});

  @override
  State<DriverRideDetailScreen> createState() => _DriverRideDetailScreenState();
}

class _DriverRideDetailScreenState extends State<DriverRideDetailScreen> {
  final BookingService _bookingService = BookingService();
  final RideService _rideService = RideService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool _isCompleting = false;
  bool _isConfirming = false;
  List<Booking> _bookings = [];
  
  // Theo dõi trạng thái xác nhận của tài xế
  bool _driverConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _checkConfirmationStatus();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tải danh sách các booking cho chuyến đi này
      final bookings = await _bookingService.getBookingsForDriver();

      // Lọc theo rideId của chuyến đi hiện tại
      final Ride rideData = widget.ride as Ride;
      final filteredBookings =
          bookings.where((b) => b.rideId == rideData.id).toList();

      setState(() {
        _bookings = filteredBookings;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách đặt chỗ: $e')),
        );
      }
    }
  }

  String _formatTime(String timeString) {
    try {
      // Parse the date string in ISO format
      final dateTime = DateTime.parse(timeString);
      // Format to display date and time với giờ được hiển thị trước 
      return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
    } catch (e) {
      print('❌ Lỗi khi định dạng thời gian: $e, timeString: $timeString');
      return timeString;
    }
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        color = Colors.green;
        label = 'Đang mở';
        break;
      case 'CANCELLED':
        color = Colors.red;
        label = 'Đã hủy';
        break;
      case 'COMPLETED':
        color = Colors.blue;
        label = 'Hoàn thành';
        break;
      case 'PENDING':
        color = Colors.orange;
        label = 'Chờ xác nhận';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _completeRide() async {
    // Lưu trữ context hiện tại để sử dụng sau khi đóng dialog
    final BuildContext currentContext = context;
    final Ride rideData = widget.ride as Ride;

    // Hiển thị dialog xác nhận
    final bool? confirmed = await showDialog<bool>(
      context: currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận hoàn thành'),
          content: const Text(
            'Bạn có chắc chắn muốn đánh dấu chuyến đi này là đã hoàn thành?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      // Sử dụng API mới cho tài xế hoàn thành chuyến đi
      final success = await _rideService.driverCompleteRide(rideData.id);

      if (!mounted) return;

      if (success) {
        // Send notification to passengers about the completed ride
        try {
          // Gửi thông báo đến tất cả hành khách đã đặt chỗ cho chuyến đi này
          if (_bookings.isNotEmpty) {
            for (var booking in _bookings) {
              // Chỉ gửi thông báo cho các booking đã được chấp nhận
              if (booking.status.toUpperCase() == 'ACCEPTED' || 
                  booking.status.toUpperCase() == 'APPROVED' ||
                  booking.status.toUpperCase() == 'IN_PROGRESS') {
                // Fetch passenger's email from backend if needed
                // For now, using a system notification without targeting a specific user
                await _notificationService.sendNotification(
                  'Tài xế đã xác nhận hoàn thành',
                  'Tài xế ${rideData.driverName} đã xác nhận hoàn thành chuyến đi từ ${rideData.departure} đến ${rideData.destination}.',
                  AppConfig.NOTIFICATION_DRIVER_CONFIRMED,
                  {
                    'rideId': rideData.id,
                    'bookingId': booking.id,
                    'status': 'DRIVER_CONFIRMED',
                  }
                  // Not specifying recipient - will be handled by backend
                );
              }
            }
          } else {
            // Nếu không có bookings, vẫn lưu thông báo vào hệ thống
            await _notificationService.sendNotification(
              'Chuyến đi hoàn thành',
              'Chuyến đi đã được đánh dấu hoàn thành bởi tài xế',
              'ride_completed',
              {
                'rideId': rideData.id,
                'status': 'COMPLETED',
              }
            );
          }
        } catch (notifError) {
          // Just log notification error, don't stop the process
          print('Lỗi khi gửi thông báo: $notifError');
        }

        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Chuyến đi đã được đánh dấu hoàn thành',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Cập nhật lại trạng thái của chuyến đi trong giao diện
        if (!mounted) return;
        setState(() {
          if (widget.ride is Ride) {
            Ride ride = widget.ride as Ride;
            ride.status = 'COMPLETED';
          }
        });
        
        // Quay về màn hình trước đó ngay lập tức sau khi hoàn thành thành công
        if (!mounted) return;
        Navigator.of(currentContext).pop(true); // Trả về true để báo hiệu hoàn thành thành công
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể hoàn thành chuyến đi. Vui lòng thử lại.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Future<void> _cancelRide() async {
    // Lưu trữ context hiện tại để sử dụng sau khi đóng dialog
    final BuildContext currentContext = context;
    final Ride rideData = widget.ride as Ride;

    // Hiển thị dialog xác nhận
    final bool? confirmed = await showDialog<bool>(
      context: currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận huỷ chuyến'),
          content: const Text('Bạn có chắc chắn muốn huỷ chuyến đi này? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Có, huỷ chuyến',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // Hiển thị dialog loading
    if (!mounted) return;
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Đang hủy chuyến đi...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      final success = await _rideService.cancelRide(rideData.id);

      // Đóng dialog loading
      if (!mounted) return;
      Navigator.of(currentContext).pop();

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã huỷ chuyến đi thành công',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Cập nhật lại trạng thái của chuyến đi trong giao diện
        if (!mounted) return;
        setState(() {
          if (widget.ride is Ride) {
            Ride ride = widget.ride as Ride;
            ride.status = 'CANCELLED';
          }
        });
        
        // Quay về màn hình trước đó ngay lập tức sau khi hủy thành công
        if (!mounted) return;
        
        // Gửi thông báo cho hành khách đã đặt chỗ
        try {
          // Thay thế phương thức sendRideCancelledNotification bằng sendNotification riêng lẻ
          // cho từng booking nhưng không gửi trực tiếp đến email hành khách
          for (var booking in _bookings.where((b) => 
              b.status.toUpperCase() == 'APPROVED' || 
              b.status.toUpperCase() == 'ACCEPTED')) {
                
            await _notificationService.sendNotification(
              'Chuyến đi đã bị hủy',
              'Chuyến đi từ ${rideData.departure} đến ${rideData.destination} đã bị hủy bởi tài xế ${rideData.driverName}.',
              AppConfig.NOTIFICATION_RIDE_CANCELLED,
              {
                'rideId': rideData.id,
                'bookingId': booking.id,
                'status': 'CANCELLED',
              }
              // Backend sẽ xử lý việc gửi thông báo đến đúng hành khách
            );
          }
        } catch (e) {
          print('Lỗi khi gửi thông báo hủy chuyến: $e');
          // Không dừng luồng vì đây không phải lỗi chính
        }
        
        Navigator.of(currentContext).pop(true); // Trả về true để báo hiệu hủy thành công
      } else {
        if (!mounted) return;
        showDialog(
          context: currentContext,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Không thể huỷ chuyến đi'),
              content: const Text(
                'Không thể huỷ chuyến đi. Nguyên nhân có thể do:\n'
                '- Chuyến đi đã bị hủy trước đó\n'
                '- Chuyến đi đã có người đặt và được chấp nhận\n'
                '- Lỗi kết nối mạng\n\n'
                'Vui lòng thử lại sau hoặc liên hệ hỗ trợ.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Đóng dialog loading
      if (!mounted) return;
      Navigator.of(currentContext).pop();

      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Đóng',
            textColor: Colors.white,
            onPressed: () {
              // Chỉ đóng snackbar, không gọi lại hàm
              scaffoldMessenger.hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  // Kiểm tra trạng thái xác nhận chuyến đi
  Future<void> _checkConfirmationStatus() async {
    try {
      final Ride rideData = widget.ride as Ride;
      
      // Call API to check if driver already confirmed this ride
      // For now, we rely on ride status
      final inProgress = rideData.status.toUpperCase() == 'IN_PROGRESS';
      
      if (mounted) {
        setState(() {
          _driverConfirmed = inProgress;
        });
      }
    } catch (e) {
      print('❌ Lỗi khi kiểm tra trạng thái xác nhận: $e');
      if (mounted) {
        setState(() {
          _driverConfirmed = false;
        });
      }
    }
  }

  Future<void> _confirmDeparture() async {
    // Lưu trữ context hiện tại để sử dụng sau khi đóng dialog
    final BuildContext currentContext = context;
    final Ride rideData = widget.ride as Ride;

    // Hiển thị dialog xác nhận
    final bool? confirmed = await showDialog<bool>(
      context: currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xuất phát'),
          content: const Text(
            'Bạn xác nhận đã đến thời điểm khởi hành chuyến đi này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      // Tài xế xác nhận khởi hành
      final success = await _rideService.driverConfirmDeparture(rideData.id);

      if (success && mounted) {
        setState(() {
          _driverConfirmed = true;
          _isConfirming = false;
        });
        
        // Gửi thông báo cho hành khách đã đặt chỗ
        try {
          // Gửi thông báo cho từng booking được chấp nhận
          for (var booking in _bookings.where((b) => 
              b.status.toUpperCase() == 'APPROVED' || 
              b.status.toUpperCase() == 'ACCEPTED')) {
            
            await _notificationService.sendNotification(
              'Chuyến đi đã bắt đầu',
              'Chuyến đi từ ${rideData.departure} đến ${rideData.destination} đã bắt đầu.',
              AppConfig.NOTIFICATION_RIDE_STARTED,
              {
                'rideId': rideData.id,
                'bookingId': booking.id,
                'status': 'IN_PROGRESS',
              }
              // Backend sẽ xử lý việc gửi thông báo đến đúng hành khách
            );
          }
        } catch (e) {
          print('Lỗi khi gửi thông báo bắt đầu chuyến: $e');
          // Không dừng luồng vì đây không phải lỗi chính
        }
        
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã xác nhận khởi hành chuyến đi',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isConfirming = false;
        });
        
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể xác nhận khởi hành. Vui lòng thử lại.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
        
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final Ride rideData = widget.ride as Ride;
    final bool isCompletedOrCancelled =
        rideData.status.toUpperCase() == 'COMPLETED' ||
        rideData.status.toUpperCase() == 'CANCELLED';
        
    // Kiểm tra nếu chuyến đi đã đến thời gian xuất phát
    final bool isReadyForDeparture = _rideService.canConfirmRide(rideData);
    final bool isInProgress = _rideService.isRideInProgress(rideData);

    return SharexeBackground2(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Chi tiết chuyến đi'),
          backgroundColor: const Color(0xFF002D72),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with ride info
              Container(
                color: const Color(0xFF002D72),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rideData.departure} → ${rideData.destination}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(rideData.startTime),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_seat,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${rideData.totalSeat} ghế',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rideData.pricePerSeat != null
                                      ? currencyFormat.format(rideData.pricePerSeat)
                                      : 'Miễn phí',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        _buildStatusIndicator(rideData.status),
                      ],
                    ),
                  ],
                ),
              ),

              // Ride details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ride details section
                    const Text(
                      'Thông tin chuyến đi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Số ghế trống:',
                      '${rideData.availableSeats}/${rideData.totalSeat} người',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Giá mỗi ghế:',
                      rideData.pricePerSeat != null
                          ? currencyFormat.format(rideData.pricePerSeat)
                          : 'Miễn phí',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Trạng thái:',
                      rideData.status.toUpperCase() == 'ACTIVE'
                          ? 'Đang mở'
                          : rideData.status.toUpperCase() == 'COMPLETED'
                          ? 'Đã hoàn thành'
                          : rideData.status.toUpperCase() == 'CANCELLED'
                          ? 'Đã hủy'
                          : rideData.status.toUpperCase() == 'IN_PROGRESS'
                          ? 'Đang diễn ra'
                          : rideData.status,
                    ),

                    const Divider(height: 32),

                    // Xác nhận xuất phát
                    if (isReadyForDeparture && !isCompletedOrCancelled && !isInProgress) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.amber.shade800,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Đã đến giờ khởi hành!',
                                  style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _driverConfirmed
                                ? 'Bạn đã xác nhận khởi hành chuyến đi này.'
                                : 'Hãy xác nhận khi bạn đã sẵn sàng để khởi hành chuyến đi.',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (!_driverConfirmed)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isConfirming ? null : _confirmDeparture,
                                  icon: _isConfirming
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.directions_car),
                                  label: Text(
                                    _isConfirming ? 'Đang xác nhận...' : 'Xác nhận xuất phát'
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            if (_driverConfirmed)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Đã xác nhận khởi hành',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Ride in progress UI
                    if (isInProgress && !isCompletedOrCancelled) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.drive_eta,
                                  color: Colors.green.shade800,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Chuyến đi đang diễn ra!',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy hoàn thành chuyến đi sau khi đã chở tất cả hành khách đến nơi.',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isCompleting ? null : _completeRide,
                                icon: _isCompleting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle),
                                label: Text(
                                  _isCompleting ? 'Đang xác nhận...' : 'Hoàn thành chuyến đi'
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Actions for the ride
                    if (!isCompletedOrCancelled && !isInProgress) ...[
                      const Text(
                        'Quản lý chuyến đi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _cancelRide,
                              icon: const Icon(Icons.cancel),
                              label: const Text('Hủy chuyến'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isCompleting ? null : _completeRide,
                              icon: const Icon(Icons.check_circle),
                              label:
                                  _isCompleting
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Hoàn thành'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 32),
                    ],

                    // Bookings list section
                    const Text(
                      'Danh sách đặt chỗ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _bookings.isEmpty
                        ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Chưa có yêu cầu đặt chỗ nào cho chuyến đi này',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Đặt chỗ #${booking.id}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                booking.status.toUpperCase() ==
                                                        'PENDING'
                                                    ? Colors.orange.withOpacity(
                                                      0.2,
                                                    )
                                                    : booking.status
                                                            .toUpperCase() ==
                                                        'APPROVED'
                                                    ? Colors.green.withOpacity(
                                                      0.2,
                                                    )
                                                    : Colors.red.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            booking.status.toUpperCase() ==
                                                    'PENDING'
                                                ? 'Chờ duyệt'
                                                : booking.status.toUpperCase() ==
                                                    'APPROVED'
                                                ? 'Đã duyệt'
                                                : 'Từ chối',
                                            style: TextStyle(
                                              color:
                                                  booking.status.toUpperCase() ==
                                                          'PENDING'
                                                      ? Colors.orange
                                                      : booking.status
                                                              .toUpperCase() ==
                                                          'APPROVED'
                                                      ? Colors.green
                                                      : Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Hành khách: ${booking.passengerName}'),
                                    Text('Số ghế: ${booking.seatsBooked}'),
                                    Text(
                                      'Thời gian đặt: ${_formatTime(booking.createdAt)}',
                                    ),

                                    if (booking.status.toUpperCase() ==
                                            'PENDING' &&
                                        !isCompletedOrCancelled) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () async {
                                              // Từ chối yêu cầu
                                              await _bookingService.rejectBooking(
                                                booking.id,
                                              );
                                              _loadBookings();
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.red,
                                            ),
                                            label: const Text(
                                              'Từ chối',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              // Chấp nhận yêu cầu
                                              final success =
                                                  await _bookingService
                                                      .acceptBooking(booking.id);
                                              if (success) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Đã chấp nhận yêu cầu',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                                _loadBookings();
                                              }
                                            },
                                            icon: const Icon(Icons.check),
                                            label: const Text('Chấp nhận'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
    );
  }
}
