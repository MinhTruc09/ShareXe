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

  // Add a static cache for formatted time strings
  static final Map<String, String> _timeFormatCache = {};

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
    // Check if this timestamp is already in the cache
    if (_timeFormatCache.containsKey(timeString)) {
      return _timeFormatCache[timeString]!;
    }

    try {
      // Parse the date string in ISO format
      final dateTime = DateTime.parse(timeString);
      // Format to display date and time
      final formatted = DateFormat('HH:mm dd/MM/yyyy').format(dateTime);

      // Store in cache for future use
      _timeFormatCache[timeString] = formatted;

      return formatted;
    } catch (e) {
      // Cache the error result too to avoid repeated parsing attempts
      _timeFormatCache[timeString] = timeString;
      return timeString;
    }
  }

  String _formatBookingTime() {
    if (bookingDTO != null) {
      try {
        final key = 'bookingDTO_${bookingDTO!.createdAt.toIso8601String()}';

        // Check cache first
        if (_timeFormatCache.containsKey(key)) {
          return _timeFormatCache[key]!;
        }

        final formatted = DateFormat(
          'HH:mm dd/MM/yyyy',
        ).format(bookingDTO!.createdAt);
        _timeFormatCache[key] = formatted;
        return formatted;
      } catch (e) {
        print('Error formatting bookingDTO createdAt: $e');
      }
    }

    if (booking != null) {
      return _formatTime(booking!.createdAt);
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
        shouldShowConfirmButton = _appConfig.shouldShowDriverConfirmButton(
          ride.status,
          startDateTime,
        );
      } else if (booking != null) {
        // Hành khách (legacy Booking): Hiển thị nút khi booking đã qua thời gian khởi hành
        // Bao gồm cả trạng thái PENDING đã qua thời gian khởi hành
        shouldShowConfirmButton = _appConfig.shouldShowPassengerConfirmButton(
          booking!.status,
          startDateTime,
        );
      } else if (bookingDTO != null) {
        // Hành khách (BookingDTO): Hiển thị nút khi booking đã qua thời gian khởi hành
        // Bao gồm cả trạng thái PENDING đã qua thời gian khởi hành
        shouldShowConfirmButton = _appConfig.shouldShowPassengerConfirmButton(
          bookingDTO!.status,
          startDateTime,
        );
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
          statusLabel = _appConfig.getBookingStatusText(
            bookingStatus,
            startDateTime,
            ride.status,
          );
        } else {
          statusLabel = _appConfig.getRideStatusText(
            ride.status,
            startDateTime,
          );
        }
      }

      // Xác định màu sắc
      switch (statusLabel) {
        case "Tài xế xác nhận":
        case "Tài xế xác nhận - Đợi bạn xác nhận":
          statusColor = Colors.green;
          break;
        case "Đang đi":
          statusColor = Colors.orange;
          break;
        case "Đã hủy":
          statusColor = Colors.red;
          break;
        case "Chờ xác nhận":
        case "Đang chờ tài xế duyệt":
          statusColor = Colors.amber;
          break;
        case "Đã được duyệt - sắp tới":
          statusColor = Colors.blue;
          break;
        case "Khách đã xác nhận":
        case "Bạn đã xác nhận - Đợi tài xế xác nhận":
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
          statusLabel = 'Tài xế xác nhận - Đợi bạn xác nhận';
          statusColor = Colors.green;
          break;
        case 'PASSENGER_CONFIRMED':
          statusLabel = 'Bạn đã xác nhận - Đợi tài xế xác nhận';
          statusColor = Colors.teal;
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
      int bookedSeats = ride.totalSeat - ride.availableSeats;
      totalPrice = ride.pricePerSeat! * bookedSeats;
    }

    // Format giá tiền với xử lý số lớn
    String formatPrice(double price) {
      if (price == 0) return "0 đ";

      try {
        // Handle large numbers gracefully
        if (price >= 1000000000) {
          // For billions, use B suffix
          return '${(price / 1000000000).toStringAsFixed(price % 1000000000 > 0 ? 2 : 0).replaceAll(RegExp(r'\.0+$'), '')}B đ';
        } else if (price >= 1000000) {
          // For millions, use M suffix
          return '${(price / 1000000).toStringAsFixed(price % 1000000 > 0 ? 1 : 0).replaceAll(RegExp(r'\.0+$'), '')}M đ';
        } else if (price >= 1000) {
          // For thousands, use K suffix
          return '${(price / 1000).toStringAsFixed(price % 1000 > 0 ? 1 : 0).replaceAll(RegExp(r'\.0+$'), '')}K đ';
        } else {
          // Use NumberFormat only for smaller numbers to avoid overflow
          return currencyFormat.format(price);
        }
      } catch (e) {
        debugPrint('Error formatting price: $e');
        // Even simpler fallback with manual formatting
        if (price >= 1000000000) {
          return '${(price / 1000000000).toStringAsFixed(1)}B đ';
        } else if (price >= 1000000) {
          return '${(price / 1000000).toStringAsFixed(1)}M đ';
        } else if (price >= 1000) {
          return '${(price / 1000).toStringAsFixed(1)}K đ';
        } else {
          return '${price.toStringAsFixed(0)} đ';
        }
      }
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
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey,
                      ),
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
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.green.shade600,
                      ),
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
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.red.shade600,
                      ),
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

                  // Số ghế và giá - Sửa để xử lý giá lớn
                  Row(
                    children: [
                      // Số lượng ghế
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_seat,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${ride.totalSeat - ride.availableSeats} ghế',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Giá mỗi ghế
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: Colors.green.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                formatPrice(ride.pricePerSeat ?? 0),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tổng tiền
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Tổng: ',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                formatPrice(totalPrice),
                                style: TextStyle(
                                  color: Colors.deepOrange.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                    child: const Icon(
                      Icons.person,
                      size: 24,
                      color: Colors.blueGrey,
                    ),
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
                        // Hiển thị số điện thoại từ BookingDTO nếu có
                        if (bookingDTO?.driverPhone != null &&
                            bookingDTO!.driverPhone.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bookingDTO!.driverPhone,
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
                            const Icon(
                              Icons.email,
                              size: 14,
                              color: Colors.grey,
                            ),
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
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.airline_seat_recline_normal,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tổng số ghế: ${ride.totalSeat}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.event_seat,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Còn trống: ${ride.availableSeats}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // Thông tin xe từ BookingDTO nếu có
                  if (bookingDTO?.vehicle != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bookingDTO!.vehicle!.brand} ${bookingDTO!.vehicle!.model}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${bookingDTO!.vehicle!.color})',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          bookingDTO!.vehicle!.licensePlate,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

            // Nút Hủy cho vị trí cuối trang (nếu cần)
            if (ride.status.toUpperCase() == 'PENDING' ||
                ride.status.toUpperCase() == 'ACTIVE')
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
