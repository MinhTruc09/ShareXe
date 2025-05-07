import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ride.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class RideDetailScreen extends StatefulWidget {
  final dynamic ride;

  const RideDetailScreen({Key? key, required this.ride}) : super(key: key);

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  bool _isBooking = false;
  bool _isBooked = false;
  Booking? _booking;
  int _selectedSeats = 1;
  StreamSubscription<DatabaseEvent>? _bookingStatusSubscription;

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
      final booking = await _bookingService.bookRide(rideData.id, _selectedSeats);
      
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }
  
  // Set up real-time listener for booking status
  void _setupBookingStatusListener(int bookingId) {
    final DatabaseReference bookingRef = FirebaseDatabase.instance.ref('bookings/$bookingId');
    
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
      builder: (context) => AlertDialog(
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
            _buildDetailItem('Thời gian cập nhật:', _formatTime(DateTime.now().toIso8601String())),
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
      builder: (context) => AlertDialog(
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
            _buildDetailItem('Thời gian đặt:', _formatTime(booking.createdAt)),
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final Ride rideData = widget.ride as Ride;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chuyến đi'),
        backgroundColor: const Color(0xFF00AEEF),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue header section with basic ride info
            Container(
              color: const Color(0xFF00AEEF),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route info
                  Row(
                    children: [
                      const Icon(Icons.circle_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rideData.departure,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Connecting line
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Container(
                      height: 30,
                      width: 2,
                      color: Colors.white,
                    ),
                  ),
                  // Destination
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rideData.destination,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Time and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thời gian khởi hành',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(rideData.startTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusIndicator(rideData.status),
                    ],
                  ),
                ],
              ),
            ),
            
            // Details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver info
                  const Text(
                    'Thông tin tài xế',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.person, color: Color(0xFF00AEEF)),
                    ),
                    title: Text(
                      rideData.driverName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(rideData.driverEmail),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message, color: Color(0xFF00AEEF)),
                          onPressed: () {
                            // Implement chat with driver
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tính năng đang phát triển')),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: Color(0xFF00AEEF)),
                          onPressed: () {
                            // Implement call driver
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tính năng đang phát triển')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 32),
                  
                  // Ride details
                  const Text(
                    'Chi tiết chuyến đi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Số ghế trống:', '${rideData.availableSeats}/${rideData.totalSeat} người'),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Giá mỗi ghế:', 
                    rideData.pricePerSeat != null 
                        ? currencyFormat.format(rideData.pricePerSeat) 
                        : 'Miễn phí'
                  ),
                  
                  if (!_isBooked && rideData.availableSeats > 0) ...[
                    const SizedBox(height: 24),
                    
                    // Seat selection
                    const Text(
                      'Chọn số ghế:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _selectedSeats > 1
                              ? () {
                                  setState(() {
                                    _selectedSeats--;
                                  });
                                }
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$_selectedSeats',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _selectedSeats < rideData.availableSeats
                              ? () {
                                  setState(() {
                                    _selectedSeats++;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Book button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isBooking ? null : _bookRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002D62),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isBooking
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Đang đặt chuyến...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Đặt chỗ ngay',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else if (_isBooked && _booking != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đã đặt chỗ thành công!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Số ghế đã đặt: ${_booking!.seatsBooked}'),
                          const SizedBox(height: 4),
                          const Text('Trạng thái: Chờ tài xế duyệt'),
                          const SizedBox(height: 8),
                          const Text(
                            'Cảm ơn bạn đã đặt chuyến! Hãy chờ tài xế xác nhận đặt chỗ của bạn.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ] else if (rideData.availableSeats <= 0) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hết chỗ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Chuyến đi này đã hết chỗ. Vui lòng chọn chuyến khác.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
} 