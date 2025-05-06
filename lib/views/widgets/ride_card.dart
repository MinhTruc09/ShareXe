import 'package:flutter/material.dart';
import '../../models/ride.dart';
import 'package:intl/intl.dart';

class RideCard extends StatelessWidget {
  final Ride ride;
  final Function()? onTap;
  final bool showFavorite;

  const RideCard({
    Key? key,
    required this.ride,
    this.onTap,
    this.showFavorite = true,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: const Color(0xFF002D62),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade200,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ride.driverEmail,
                        style: TextStyle(
                          color: Colors.blue.shade100,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (showFavorite)
                    const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle_outlined, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Xuất phát từ:',
                              style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            ride.departure,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Điểm đến:',
                              style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            ride.destination,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Thời gian xuất phát:',
                        style: TextStyle(color: Colors.blue.shade100, fontSize: 12),
                      ),
                      Text(
                        _formatTime(ride.startTime),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ride.availableSeats ?? 0}/${ride.totalSeat ?? 0} người',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.pricePerSeat != null 
                            ? currencyFormat.format(ride.pricePerSeat)
                            : 'Miễn phí',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildStatusIndicator(ride.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 