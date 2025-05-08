import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/ride_service.dart';
import '../../widgets/ride_card.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class DriverRideDetailScreen extends StatefulWidget {
  final dynamic ride;

  const DriverRideDetailScreen({Key? key, required this.ride})
    : super(key: key);

  @override
  State<DriverRideDetailScreen> createState() => _DriverRideDetailScreenState();
}

class _DriverRideDetailScreenState extends State<DriverRideDetailScreen> {
  final BookingService _bookingService = BookingService();
  final RideService _rideService = RideService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool _isCompleting = false;
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tải danh sách các booking cho chuyến đi này
      final bookings = await _bookingService.getDriverBookings();

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

  Future<void> _completeRide() async {
    final Ride rideData = widget.ride as Ride;

    // Hiển thị dialog xác nhận
    final bool? confirmed = await showDialog<bool>(
      context: context,
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

    if (confirmed != true) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final success = await _rideService.completeRide(rideData.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chuyến đi đã được đánh dấu hoàn thành'),
          ),
        );

        // Cập nhật lại trạng thái của chuyến đi trong giao diện
        setState(() {
          final updatedRide = Ride(
            id: rideData.id,
            availableSeats: rideData.availableSeats,
            driverName: rideData.driverName,
            driverEmail: rideData.driverEmail,
            departure: rideData.departure,
            destination: rideData.destination,
            startTime: rideData.startTime,
            pricePerSeat: rideData.pricePerSeat,
            totalSeat: rideData.totalSeat,
            status: 'COMPLETED',
          );

          // Cập nhật widget.ride
          if (widget.ride is Ride) {
            (widget.ride as dynamic).status = 'COMPLETED';
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể hoàn thành chuyến đi. Vui lòng thử lại.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      setState(() {
        _isCompleting = false;
      });
    }
  }

  Future<void> _cancelRide() async {
    final Ride rideData = widget.ride as Ride;

    // Hiển thị dialog xác nhận
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận huỷ chuyến'),
          content: const Text('Bạn có chắc chắn muốn huỷ chuyến đi này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Có, huỷ chuyến'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _rideService.cancelRide(rideData.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã huỷ chuyến đi thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Cập nhật lại trạng thái của chuyến đi trong giao diện
        setState(() {
          if (widget.ride is Ride) {
            (widget.ride as dynamic).status = 'CANCELLED';
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể huỷ chuyến đi. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final Ride rideData = widget.ride as Ride;
    final bool isCompletedOrCancelled =
        rideData.status.toUpperCase() == 'COMPLETED' ||
        rideData.status.toUpperCase() == 'CANCELLED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý chuyến đi'),
        backgroundColor: const Color(0xFF002D72),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
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
                  // Route info
                  Row(
                    children: [
                      const Icon(
                        Icons.circle_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
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
                    child: Container(height: 30, width: 2, color: Colors.white),
                  ),
                  // Destination
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
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
                        : rideData.status,
                  ),

                  const Divider(height: 32),

                  // Actions for the ride
                  if (!isCompletedOrCancelled) ...[
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
                                                  ),
                                                ),
                                              );
                                              _loadBookings();
                                            }
                                          },
                                          icon: const Icon(Icons.check),
                                          label: const Text('Chấp nhận'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
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
    );
  }
}
