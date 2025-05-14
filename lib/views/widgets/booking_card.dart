import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../utils/app_config.dart';

class BookingCard extends StatelessWidget {
  final BookingDTO booking;
  final Function()? onTap;
  final Function()? onConfirmComplete;
  final Function()? onCancel;
  final bool showCancelButton;
  
  final AppConfig _appConfig = AppConfig();

  BookingCard({
    Key? key,
    required this.booking,
    this.onTap,
    this.onConfirmComplete,
    this.onCancel,
    this.showCancelButton = false,
  }) : super(key: key);

  // Format thời gian
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  // Format thời gian đặt
  String _formatBookingTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt);
  }

  // Format tiền tệ
  String _formatCurrency(double amount) {
    if (amount == 0) return "0 đ";
    
    try {
      final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
      return formatter.format(amount);
    } catch (e) {
      // Fallback nếu có lỗi
      return "$amount đ";
    }
  }

  // Lấy màu sắc dựa vào trạng thái booking
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.amber;
      case 'ACCEPTED':
      case 'APPROVED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'DRIVER_CONFIRMED':
        return Colors.green;
      case 'PASSENGER_CONFIRMED':
        return Colors.teal;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Lấy văn bản hiển thị dựa vào trạng thái booking
  String _getStatusText(String status, DateTime startTime) {
    final now = DateTime.now();
    status = status.toUpperCase();

    // Hiển thị theo trạng thái booking
    switch (status) {
      case 'PENDING':
        return "Đang chờ tài xế duyệt";
      case 'ACCEPTED':
      case 'APPROVED':
        if (now.isAfter(startTime)) {
          return "Đang đi";
        } else {
          return "Đã được duyệt - sắp tới";
        }
      case 'IN_PROGRESS':
        return "Đang đi";
      case 'PASSENGER_CONFIRMED':
        return "Bạn đã xác nhận - Đợi tài xế xác nhận";
      case 'DRIVER_CONFIRMED':
        return "Tài xế xác nhận - Đợi bạn xác nhận";
      case 'COMPLETED':
        return "Đã hoàn thành";
      case 'CANCELLED':
        return "Đã hủy";
      case 'REJECTED':
        return "Từ chối";
      default:
        return "Trạng thái không xác định: $status";
    }
  }

  // Kiểm tra xem có nên hiển thị nút xác nhận cho tài xế không
  bool _shouldShowDriverConfirmButton() {
    if (onConfirmComplete == null) return false;
    
    final status = booking.status.toUpperCase();
    
    // Chỉ hiển thị nút xác nhận khi trạng thái là IN_PROGRESS hoặc PASSENGER_CONFIRMED
    return status == 'IN_PROGRESS' || status == 'PASSENGER_CONFIRMED';
  }

  // Kiểm tra xem có nên hiển thị nút xác nhận cho hành khách không
  bool _shouldShowPassengerConfirmButton() {
    if (onConfirmComplete == null) return false;
    
    final status = booking.status.toUpperCase();
    final now = DateTime.now();
    
    return (status == 'PENDING' ||
            status == 'ACCEPTED' ||
            status == 'APPROVED' ||
            status == 'IN_PROGRESS' ||
            status == 'DRIVER_CONFIRMED') &&
            status != 'PASSENGER_CONFIRMED' &&
            status != 'COMPLETED' &&
            now.isAfter(booking.startTime);
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _getStatusText(booking.status, booking.startTime);
    final statusColor = _getStatusColor(booking.status);
    
    // Kiểm tra xem booking có bị hủy không
    final bool isCancelled = booking.status.toUpperCase() == 'CANCELLED' || 
                           booking.status.toUpperCase() == 'REJECTED';
    
    // Kiểm tra nếu nên hiển thị nút xác nhận cho hành khách
    final bool shouldShowPassengerConfirmButton = _shouldShowPassengerConfirmButton();
    
    // Kiểm tra nếu nên hiển thị nút xác nhận cho tài xế
    final bool shouldShowDriverConfirmButton = _shouldShowDriverConfirmButton();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: InkWell(
        onTap: isCancelled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: isCancelled ? Colors.transparent : null,
        highlightColor: isCancelled ? Colors.transparent : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với mã booking và trạng thái
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking #${booking.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Chip(
                    label: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            
            // Thông tin chuyến đi
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin thời gian
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(booking.startTime),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Điểm đi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.green.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.departure,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Điểm đến
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.destination,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Thông tin về số ghế và giá tiền
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_seat, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${booking.seatsBooked} ghế',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(booking.totalPrice),
                        style: TextStyle(
                          color: Colors.deepOrange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Thông tin tài xế
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  // Avatar tài xế
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: booking.driverAvatarUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              booking.driverAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: Colors.grey),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xe ${booking.driverName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              booking.driverPhone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Thời gian đặt
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Đặt lúc:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _formatBookingTime(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // DRIVER_CONFIRMED - Hiển thị thông báo và nút xác nhận
            if (booking.status.toUpperCase() == 'DRIVER_CONFIRMED' && !isCancelled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Text(
                        'Tài xế đã xác nhận hoàn thành chuyến đi. Vui lòng xác nhận để hoàn tất.',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Xác nhận hoàn thành'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: onConfirmComplete,
                      ),
                    ),
                  ],
                ),
              ),
            
            // PASSENGER_CONFIRMED - Hiển thị thông báo
            if (booking.status.toUpperCase() == 'PASSENGER_CONFIRMED' && !isCancelled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: const Text(
                    'Bạn đã xác nhận hoàn thành chuyến đi. Đang đợi tài xế xác nhận để hoàn tất.',
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            // Hiển thị nút làm mới
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Làm mới'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
            ),
            
            // Hiển thị nút xác nhận hoàn thành cho tài xế (nếu trạng thái phù hợp)
            if (shouldShowDriverConfirmButton && !isCancelled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirmComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xác nhận hoàn thành'),
                  ),
                ),
              ),
            
            // Hiển thị nút xác nhận hoàn thành cho hành khách (nếu trạng thái phù hợp)
            if (shouldShowPassengerConfirmButton && 
                booking.status.toUpperCase() != 'DRIVER_CONFIRMED' &&
                !isCancelled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirmComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Xác nhận hoàn thành'),
                  ),
                ),
              ),
            
            // Nút hủy (nếu được yêu cầu)
            if (showCancelButton && !isCancelled && 
                (booking.status.toUpperCase() == 'PENDING' || 
                 booking.status.toUpperCase() == 'ACCEPTED' || 
                 booking.status.toUpperCase() == 'APPROVED'))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text(
                        'Hủy booking',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: onCancel,
                    ),
                  ],
                ),
              ),
            
            // Thông báo đã hủy
            if (isCancelled)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    booking.status.toUpperCase() == 'REJECTED'
                        ? 'Booking đã bị từ chối bởi tài xế'
                        : 'Booking đã bị hủy',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 