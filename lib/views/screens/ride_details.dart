import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../../models/ride.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../../models/booking.dart';
import '../../services/chat_service.dart';
import 'chat/chat_room_screen.dart';
import 'package:flutter/foundation.dart';
import '../widgets/custom_button.dart';
import '../../services/ride_service.dart';
import '../../services/auth_manager.dart';
import '../../utils/alerts.dart';

class RideDetailScreen extends StatefulWidget {
  final dynamic ride;

  const RideDetailScreen({Key? key, required this.ride}) : super(key: key);

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();
  bool _isBooking = false;
  bool _isBooked = false;
  Booking? _booking;
  int _selectedSeats = 1;
  StreamSubscription<DatabaseEvent>? _bookingStatusSubscription;
  String _bookingError = '';
  String _bookingSuccess = '';

  @override
  void dispose() {
    _bookingStatusSubscription?.cancel();
    super.dispose();
  }

  String _formatTime(String timeString) {
    try {
      // Parse the date string in ISO format
      final dateTime = DateTime.parse(timeString);
      // Format to display date and time
      return DateFormat('HH:mm dd/MM/yyyy').format(dateTime);
    } catch (e) {
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

  Future<void> _bookRide() async {
    final Ride rideData = widget.ride as Ride;

    setState(() {
      _isBooking = true;
    });

    try {
      final booking = await _bookingService.bookRide(
        rideData.id,
        _selectedSeats,
      );

      setState(() {
        _isBooking = false;
        if (booking != null) {
          _isBooked = true;
          _booking = booking;

          // Set up real-time listener for this booking
          _setupBookingStatusListener(booking.id);
        }
      });

      if (booking != null) {
        _showBookingSuccessDialog(booking);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi đặt chuyến')),
        );
      }
    } catch (e) {
      setState(() {
        _isBooking = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // Set up real-time listener for booking status
  void _setupBookingStatusListener(int bookingId) {
    final DatabaseReference bookingRef = FirebaseDatabase.instance.ref(
      'bookings/$bookingId',
    );

    _bookingStatusSubscription = bookingRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final updatedBooking = Booking.fromJson(data);

          setState(() {
            _booking = updatedBooking;
          });

          // Show notification if status changed to APPROVED
          if (updatedBooking.status == 'APPROVED') {
            _showDriverAcceptedDialog(updatedBooking);
          }
        } catch (e) {
          print('Error parsing booking data: $e');
        }
      }
    });

    // Initial setup of the booking in the database
    bookingRef.set(_booking!.toJson());
  }

  // Show notification when driver accepts booking
  void _showDriverAcceptedDialog(Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Tài xế đã chấp nhận'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tài xế đã chấp nhận đơn đặt chuyến của bạn!',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildDetailItem('Mã đặt chỗ:', '#${booking.id}'),
                _buildDetailItem('Số ghế:', '${booking.seatsBooked}'),
                _buildDetailItem('Trạng thái:', 'Đã chấp nhận'),
                _buildDetailItem(
                  'Thời gian cập nhật:',
                  _formatTime(DateTime.now().toIso8601String()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  void _showBookingSuccessDialog(Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Đặt chuyến thành công'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đặt chuyến thành công, đang chờ tài xế duyệt.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildDetailItem('Mã đặt chỗ:', '#${booking.id}'),
                _buildDetailItem('Số ghế:', '${booking.seatsBooked}'),
                _buildDetailItem('Trạng thái:', 'Chờ tài xế duyệt'),
                _buildDetailItem(
                  'Thời gian đặt:',
                  _formatTime(booking.createdAt),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _startChatWithDriver() async {
    try {
      // Lấy thông tin chuyến đi
      final rideData = widget.ride;
      final driverEmail = rideData.driverEmail;
      final driverName = rideData.driverName;

      if (driverEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin tài xế')),
        );
        return;
      }

      // Hiển thị loading
      setState(() {
        _isBooking = true;
      });

      // Tạo phòng chat hoặc lấy phòng chat hiện có
      final roomId = await _chatService.createOrGetChatRoom(driverEmail);

      // Ẩn loading
      setState(() {
        _isBooking = false;
      });

      if (roomId != null) {
        if (mounted) {
          // Chuyển đến màn hình chat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatRoomScreen(
                    roomId: roomId,
                    partnerName: driverName,
                    partnerEmail: driverEmail,
                  ),
            ),
          );
        }
      } else {
        throw Exception('Không thể tạo phòng chat');
      }
    } catch (e) {
      setState(() {
        _isBooking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể kết nối với tài xế: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final Ride rideData = widget.ride as Ride;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chuyến đi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isBooking
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Từ ${rideData.departure} đến ${rideData.destination}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      'Thời gian khởi hành:',
                      _formatTime(rideData.startTime),
                    ),
                    _buildDetailItem('Tài xế:', rideData.driverName),
                    _buildDetailItem(
                      'Ghế trống:',
                      '${rideData.availableSeats}/${rideData.totalSeat}',
                    ),
                    if (rideData.pricePerSeat != null)
                      _buildDetailItem(
                        'Giá:',
                        '${NumberFormat.currency(locale: 'vi-VN', symbol: '₫').format(rideData.pricePerSeat)}/ghế',
                      ),
                    _buildDetailItem('Trạng thái:', rideData.status),

                    if (!_isBooked &&
                        rideData.availableSeats > 0 &&
                        rideData.status == 'ACTIVE')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'Số ghế bạn muốn đặt:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedSeats,
                            items: List.generate(
                              rideData.availableSeats,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text('${index + 1}'),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedSeats = value!;
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!_isBooked &&
                            rideData.availableSeats > 0 &&
                            rideData.status == 'ACTIVE')
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isBooking ? null : _bookRide,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF002D62),
                                foregroundColor: Colors.white,
                              ),
                              child:
                                  _isBooking
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Đặt chỗ'),
                            ),
                          ),
                        if (!_isBooked &&
                            rideData.availableSeats > 0 &&
                            rideData.status == 'ACTIVE')
                          const SizedBox(width: 10),
                        // Nút chat với tài xế hoặc hành khách
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _openChatWithPartner(rideData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Nhắn tin'),
                          ),
                        ),
                      ],
                    ),

                    if (_isBooked) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Thông tin đặt chỗ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _booking != null
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailItem(
                                'Mã đặt chỗ:',
                                '#${_booking!.id}',
                              ),
                              _buildDetailItem(
                                'Số ghế đã đặt:',
                                '${_booking!.seatsBooked}',
                              ),
                              _buildDetailItem('Trạng thái:', _booking!.status),
                              _buildDetailItem(
                                'Thời gian đặt:',
                                _formatTime(_booking!.createdAt),
                              ),
                            ],
                          )
                          : const Text('Đang tải thông tin...'),
                    ],

                    if (_bookingError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _bookingError,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    if (_bookingSuccess.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _bookingSuccess,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  // Mở chat với đối tác (tài xế hoặc hành khách)
  Future<void> _openChatWithPartner(Ride rideData) async {
    try {
      final userRole = await AuthManager().getUserRole();
      final ChatService chatService = ChatService();
      String partnerEmail;
      String partnerName;

      // Lấy thông tin đối tác dựa vào vai trò người dùng
      if (userRole == 'DRIVER') {
        // Tài xế muốn nhắn tin với hành khách
        if (_booking == null) {
          AlertUtils.showErrorDialog(
            context,
            'Thông báo',
            'Không có thông tin hành khách để nhắn tin',
          );
          return;
        }
        // Lưu ý: Booking có thể không có passengerEmail
        // Sử dụng một email mặc định hoặc suy ra từ thông tin khác
        partnerEmail = 'passenger${_booking!.passengerId}@example.com';
        partnerName = _booking!.passengerName;
      } else {
        // Hành khách muốn nhắn tin với tài xế
        partnerEmail = rideData.driverEmail;
        partnerName = rideData.driverName;
      }

      if (kDebugMode) {
        print('Bắt đầu chat với $partnerName ($partnerEmail)');
      }

      // Hiển thị đang xử lý
      setState(() {
        _isBooking = true;
      });

      // Tạo phòng chat
      final roomId = await chatService.createOrGetChatRoom(partnerEmail);

      setState(() {
        _isBooking = false;
      });

      if (roomId == null) {
        if (mounted) {
          AlertUtils.showErrorDialog(
            context,
            'Thông báo',
            'Không thể tạo phòng chat với $partnerName',
          );
        }
        return;
      }

      // Nếu roomId bắt đầu bằng "mock_", hiển thị thông báo thông tin cho người dùng
      if (roomId.startsWith('mock_')) {
        if (mounted) {
          AlertUtils.showSnackBar(
            context,
            'Đang sử dụng chế độ chat ngoại tuyến. Tin nhắn sẽ được lưu cục bộ.',
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
          );
        }
      }

      // Mở màn hình chat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatRoomScreen(
                  roomId: roomId,
                  partnerName: partnerName,
                  partnerEmail: partnerEmail,
                ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi mở chat: $e');
      }

      setState(() {
        _isBooking = false;
      });

      if (mounted) {
        // Tạo phòng chat mô phỏng khi có lỗi
        _createMockChatAndNavigate(rideData);
      }
    }
  }

  // Tạo phòng chat mô phỏng và chuyển hướng
  Future<void> _createMockChatAndNavigate(Ride rideData) async {
    try {
      final userRole = await AuthManager().getUserRole();
      final userEmail = await AuthManager().getUserEmail();

      if (userEmail == null) {
        AlertUtils.showErrorDialog(
          context,
          'Lỗi',
          'Không thể xác thực người dùng. Vui lòng đăng nhập lại.',
        );
        return;
      }

      String partnerEmail;
      String partnerName;

      // Xác định đối tác chat dựa vào vai trò
      if (userRole == 'DRIVER') {
        if (_booking == null) {
          AlertUtils.showErrorDialog(
            context,
            'Thông báo',
            'Không có thông tin hành khách để nhắn tin',
          );
          return;
        }
        partnerEmail = 'passenger${_booking!.passengerId}@example.com';
        partnerName = _booking!.passengerName;
      } else {
        partnerEmail = rideData.driverEmail;
        partnerName = rideData.driverName;
      }

      // Tạo ID phòng chat mô phỏng
      List<String> emails = [userEmail, partnerEmail];
      emails.sort(); // Sắp xếp để đảm bảo thứ tự không đổi
      String roomId = 'mock_${emails[0]}_${emails[1]}';

      if (kDebugMode) {
        print('Tạo phòng chat mô phỏng với ID: $roomId');
      }

      // Thông báo cho người dùng
      if (mounted) {
        AlertUtils.showSnackBar(
          context,
          'Đang sử dụng chế độ chat ngoại tuyến. Tin nhắn sẽ được lưu cục bộ.',
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 5),
        );
      }

      // Mở phòng chat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatRoomScreen(
                  roomId: roomId,
                  partnerName: partnerName,
                  partnerEmail: partnerEmail,
                ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi tạo phòng chat mô phỏng: $e');
      }

      if (mounted) {
        AlertUtils.showErrorDialog(
          context,
          'Lỗi',
          'Không thể tạo phòng chat: ${e.toString()}',
        );
      }
    }
  }
}
