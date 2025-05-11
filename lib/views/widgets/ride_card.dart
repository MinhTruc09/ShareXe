import 'package:flutter/material.dart';
import '../../models/ride.dart';
import '../../models/booking.dart';
import 'package:intl/intl.dart';
import '../../utils/app_config.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final Booking? booking;
  final BookingDTO? bookingDTO;
  final Function()? onTap;
  final bool showFavorite;
  final bool showStatus;
  final Function()? onConfirmComplete;
  final bool isDriverView;
  final AppConfig _appConfig = AppConfig();

  RideCard({
    Key? key,
    required this.ride,
    this.booking,
    this.bookingDTO,
    this.onTap,
    this.showFavorite = true,
    this.showStatus = true,
    this.onConfirmComplete,
    this.isDriverView = false,
  }) : super(key: key);

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

  String _formatBookingTime() {
    if (bookingDTO != null) {
      try {
        return DateFormat('HH:mm dd/MM/yyyy').format(bookingDTO!.createdAt);
      } catch (e) {
        print('Error formatting bookingDTO createdAt: $e');
      }
    }
    
    if (booking != null) {
      try {
        return _formatTime(booking!.createdAt);
      } catch (e) {
        print('Error formatting booking createdAt: $e');
      }
    }
    
    return "N/A";
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    DateTime? startDateTime;
    
    try {
      startDateTime = DateTime.parse(ride.startTime);
    } catch (e) {
      print('Error parsing startTime: $e');
    }
    
    // Determine if confirmation button should be shown
    bool shouldShowConfirmButton = false;
    
    if (startDateTime != null && onConfirmComplete != null) {
      if (isDriverView) {
        // Tài xế: Hiển thị nút khi chuyến đi đang diễn ra và chưa xác nhận
        shouldShowConfirmButton = _appConfig.shouldShowDriverConfirmButton(ride.status, startDateTime);
      } else if (booking != null) {
        // Hành khách (legacy Booking): Hiển thị nút khi booking đã được duyệt và đến giờ
        shouldShowConfirmButton = _appConfig.shouldShowPassengerConfirmButton(booking!.status, startDateTime);
      } else if (bookingDTO != null) {
        // Hành khách (BookingDTO): Hiển thị nút khi booking đã được duyệt và đến giờ
        shouldShowConfirmButton = _appConfig.shouldShowPassengerConfirmButton(bookingDTO!.status, startDateTime);
      }
    }

    // Lấy trạng thái hiển thị dựa trên status và startDateTime
    String statusLabel = "";
    Color statusColor = Colors.green;
    if (startDateTime != null && showStatus) {
      if (isDriverView) {
        statusLabel = _appConfig.getRideStatusText(ride.status, startDateTime);
      } else {
        // Xử lý cho view của hành khách
        if (booking != null || bookingDTO != null) {
          String bookingStatus = booking?.status ?? bookingDTO?.status ?? "";
          statusLabel = _appConfig.getBookingStatusText(bookingStatus, startDateTime, ride.status);
        } else {
          statusLabel = _appConfig.getRideStatusText(ride.status, startDateTime);
        }
      }
      
      // Xác định màu sắc
      switch (statusLabel) {
        case "Tài xế đã xác nhận":
          statusColor = Colors.green;
          break;
        case "Đang diễn ra":
          statusColor = Colors.orange;
          break;
        case "Đã hủy":
          statusColor = Colors.red;
          break;
        case "Chờ xác nhận":
        case "Đang chờ tài xế duyệt":
          statusColor = Colors.amber;
          break;
        case "Đã được duyệt - sắp diễn ra":
          statusColor = Colors.blue;
          break;
        case "Đã xác nhận từ khách":
          statusColor = Colors.teal;
          break;
        case "Đã hoàn thành":
          statusColor = Colors.green.shade700;
          break;
        case "Từ chối":
          statusColor = Colors.red.shade700;
          break;
        default:
          statusColor = Colors.grey;
      }
    } else {
      // Fallback khi không có startTime
      switch (ride.status.toUpperCase()) {
        case 'DRIVER_CONFIRMED':
          statusLabel = 'Tài xế đã xác nhận';
          statusColor = Colors.green;
          break;
        case 'PENDING':
          statusLabel = 'Chờ xác nhận';
          statusColor = Colors.amber;
          break;
        default:
          statusLabel = ride.status;
          statusColor = Colors.grey;
      }
    }

    // Format thời gian
    String formattedDate = "";
    String formattedTime = "";
    try {
      if (startDateTime != null) {
        formattedDate = DateFormat('dd/MM/yyyy').format(startDateTime);
        formattedTime = DateFormat('HH:mm').format(startDateTime);
      }
    } catch (e) {
      print('Error formatting time: $e');
      formattedDate = "N/A";
      formattedTime = "N/A";
    }

    // Tính tổng giá
    double totalPrice = 0;
    if (ride.pricePerSeat != null) {
      int bookedSeats = (ride.totalSeat ?? 0) - (ride.availableSeats ?? 0);
      totalPrice = (ride.pricePerSeat ?? 0) * bookedSeats;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.blue.shade100, width: 0.5),
      ),
      elevation: 3,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với tiêu đề và trạng thái
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chuyến đi #${ride.id}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (showStatus && statusLabel.isNotEmpty)
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            
            // Phần thông tin chuyến đi
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ngày và thời gian
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Địa điểm đi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.departure,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Địa điểm đến
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.destination,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Số ghế và giá
                  Row(
                    children: [
                      Text(
                        '${ride.totalSeat - (ride.availableSeats ?? 0)} ghế × ${currencyFormat.format(ride.pricePerSeat ?? 0)}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currencyFormat.format(totalPrice),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Divider
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            
            // Thông tin tài xế
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Avatar tài xế
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 24, color: Colors.blueGrey),
                  ),
                  const SizedBox(width: 12),
                  // Thông tin tài xế
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xe ' + ride.driverName,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '1234567890', // Thay thế bằng số điện thoại thực tế nếu có
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              ride.driverEmail,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Thông tin phụ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Tổng số ghế: ${ride.totalSeat ?? 0}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Còn trống: ${ride.availableSeats ?? 0}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Hiển thị thông tin thời gian đặt chỗ (nếu có)
            if (booking != null || bookingDTO != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Đặt lúc: ${_formatBookingTime()}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Nút xác nhận hoàn thành
            if (shouldShowConfirmButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onConfirmComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Xác nhận hoàn thành",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
            // Nút Hủy cho vị trí cuối trang (nếu cần)
            if (ride.status.toUpperCase() == 'PENDING' || ride.status.toUpperCase() == 'ACTIVE')
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 16),
                  child: TextButton(
                    onPressed: () {
                      // Implement hủy logic if needed
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
