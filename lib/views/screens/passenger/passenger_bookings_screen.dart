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
import '../common/ride_details.dart';

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

    // Booking đã quá ngày xuất phát và vẫn ở trạng thái PENDING
    return now.isAfter(booking.startTime) && booking.status.toUpperCase() == 'PENDING';
  }

  // Kiểm tra xem booking có đang diễn ra hay không
  bool _isBookingInProgress(BookingDTO booking) {
    if (booking.status.toUpperCase() != 'ACCEPTED' && 
        booking.status.toUpperCase() != 'DRIVER_CONFIRMED' && 
        booking.status.toUpperCase() != 'PASSENGER_CONFIRMED') return false;

    final DateTime now = DateTime.now();

    // Ngày hiện tại là ngày xuất phát hoặc sau đó tối đa 1 ngày
    // và booking đã được chấp nhận
    final DateTime endTime = booking.startTime.add(const Duration(days: 1));
    return (now.isAfter(booking.startTime) || _isSameDay(now, booking.startTime)) && 
           now.isBefore(endTime);
  }

  // Kiểm tra hai ngày có cùng ngày không (bỏ qua giờ)
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  // Kiểm tra xem có thể hủy booking không (còn ít nhất 15 phút trước giờ khởi hành)
  bool _canCancelBooking(BookingDTO booking) {
    if (booking.status.toUpperCase() != 'PENDING' && booking.status.toUpperCase() != 'ACCEPTED') {
      return false;
    }
    
    final DateTime now = DateTime.now();
    
    // Còn ít nhất 15 phút trước giờ khởi hành
    return booking.startTime.difference(now).inMinutes >= 15;
  }

  Future<void> _loadBookings() async {
    print('🔄 Bắt đầu tải danh sách bookings của hành khách');
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy tất cả booking của hành khách sử dụng API mới
      final bookings = await _bookingService.getPassengerBookingsDTO();
      print('📦 Nhận được ${bookings.length} bookings từ API');
      
      // Log các booking nhận được để kiểm tra
      for (var booking in bookings) {
        print('📋 Booking #${booking.id} - Ride #${booking.rideId} - Status: ${booking.status}');
      }
      
      // Phân loại bookings theo trạng thái
      final upcomingList = <BookingDTO>[];
      final inProgressList = <BookingDTO>[];
      final completedList = <BookingDTO>[];
      final cancelledOrExpiredList = <BookingDTO>[];

      for (var booking in bookings) {
        if (booking.status.toUpperCase() == 'COMPLETED') {
          completedList.add(booking);
        } else if (booking.status.toUpperCase() == 'CANCELLED' || 
                  booking.status.toUpperCase() == 'REJECTED') {
          cancelledOrExpiredList.add(booking);
        } else if (_isBookingExpired(booking)) {
          // Booking đã hết hạn (quá ngày mà không được chấp nhận)
          cancelledOrExpiredList.add(booking);
        } else if (_isBookingInProgress(booking)) {
          // Booking đang diễn ra (ngày hiện tại là ngày xuất phát và đã được chấp nhận)
          inProgressList.add(booking);
        } else {
          // Các booking còn lại: chờ duyệt hoặc đã được chấp nhận nhưng chưa đến ngày
          upcomingList.add(booking);
        }
      }

      print('📊 Phân loại bookings: ${upcomingList.length} sắp tới, ${inProgressList.length} đang diễn ra, ${completedList.length} hoàn thành, ${cancelledOrExpiredList.length} đã hủy/hết hạn');

      setState(() {
        _upcomingBookings = upcomingList;
        _inProgressBookings = inProgressList;
        _completedBookings = completedList;
        _cancelledOrExpiredBookings = cancelledOrExpiredList;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi khi tải danh sách bookings: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách đặt chỗ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Phương thức để được gọi từ bên ngoài khi cần làm mới danh sách
  void refreshBookings() {
    print('🔄 Yêu cầu làm mới danh sách bookings từ bên ngoài');
    _loadBookings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kiểm tra nếu màn hình được mở lại từ màn hình chi tiết
    print('🔄 didChangeDependencies: Làm mới danh sách bookings');
    _loadBookings();
  }

  // Toggle expanded state for a booking card
  void _toggleExpanded(int bookingId) {
    setState(() {
      _expandedState[bookingId] = !(_expandedState[bookingId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharexeBackground1(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF00AEEF),
          title: const Text('Chuyến đi của tôi'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Sắp tới'),
              Tab(text: 'Đang đi'),
              Tab(text: 'Hoàn thành'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : RefreshIndicator(
                onRefresh: _loadBookings,
                color: const Color(0xFF00AEEF),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingListView(_upcomingBookings, 'upcoming'),
                    _buildBookingListView(_inProgressBookings, 'in-progress'),
                    _buildBookingListView(_completedBookings, 'completed'),
                    _buildBookingListView(_cancelledOrExpiredBookings, 'cancelled'),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBookingListView(List<BookingDTO> bookings, String type) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (bookings.isEmpty) {
      String message = '';
      
      switch (type) {
        case 'upcoming':
          message = 'Bạn chưa có chuyến đi nào sắp tới';
          break;
        case 'in-progress':
          message = 'Bạn không có chuyến đi nào đang diễn ra';
          break;
        case 'completed':
          message = 'Bạn chưa có chuyến đi nào đã hoàn thành';
          break;
        case 'cancelled':
          message = 'Bạn không có chuyến đi nào đã hủy hoặc hết hạn';
          break;
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final isExpanded = _expandedState[booking.id] ?? false;
          
          return _buildBookingCard(booking, type, isExpanded);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingDTO booking, String type, bool isExpanded) {
    // Format date strings
    final formattedDate = DateFormat('dd/MM/yyyy').format(booking.startTime);
    final formattedTime = DateFormat('HH:mm').format(booking.startTime);
    final formattedCreatedAt = DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt);
    
    // Status color and text
    Color statusColor;
    String statusText;
    
    switch (booking.status.toUpperCase()) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'Chờ xác nhận';
        break;
      case 'ACCEPTED':
        statusColor = Colors.blue;
        statusText = 'Đã chấp nhận';
        break;
      case 'DRIVER_CONFIRMED':
        statusColor = Colors.green;
        statusText = 'Tài xế đã xác nhận';
        break;
      case 'PASSENGER_CONFIRMED':
        statusColor = Colors.green;
        statusText = 'Hành khách đã xác nhận';
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusText = 'Đã từ chối';
        break;
      default:
        statusColor = Colors.grey;
        statusText = booking.status;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _toggleExpanded(booking.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with expandable icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chuyến đi #${booking.rideId}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blueAccent[700],
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Time and date info
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Departure and destination
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.departure,
                          style: const TextStyle(color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.destination,
                          style: const TextStyle(color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Basic booking info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${booking.seatsBooked} ghế × ${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(booking.pricePerSeat)}đ',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      Text(
                        '${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(booking.totalPrice)}đ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  // Expanded content
                  if (isExpanded) ...[
                    const Divider(height: 24),
                    
                    // Driver information
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: booking.driverAvatarUrl != null
                            ? NetworkImage(booking.driverAvatarUrl!)
                            : null,
                        child: booking.driverAvatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        booking.driverName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Text(booking.driverPhone),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 16, color: Colors.blueGrey),
                              const SizedBox(width: 4),
                              Text(booking.driverEmail),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Additional ride details
                    Row(
                      children: [
                        const Icon(Icons.event_seat, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text('Tổng số ghế: ${booking.totalSeats}'),
                        const SizedBox(width: 16),
                        const Icon(Icons.event_available, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text('Còn trống: ${booking.availableSeats}'),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Booking creation info
                    Row(
                      children: [
                        const Icon(Icons.history, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text('Đặt lúc: $formattedCreatedAt'),
                      ],
                    ),
                  ],
                  
                  // Show expand/collapse indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.blueGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action buttons based on booking status
            if (type == 'upcoming' && _canCancelBooking(booking))
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _cancelBooking(booking),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              
            if (type == 'in-progress' && booking.status.toUpperCase() == 'ACCEPTED')
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _confirmBookingComplete(booking),
                      child: const Text(
                        'Xác nhận hoàn thành',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Hủy booking
  Future<void> _cancelBooking(BookingDTO booking) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy chuyến đi'),
        content: const Text('Bạn có chắc chắn muốn hủy đặt chỗ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              // Call the new API to cancel booking
              final success = await _bookingService.cancelBookingDTO(booking.id);
              
              setState(() {
                _isLoading = false;
              });
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã hủy đặt chỗ thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadBookings(); // Refresh list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể hủy đặt chỗ. Vui lòng thử lại sau.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }

  // Xác nhận hoàn thành chuyến đi
  Future<void> _confirmBookingComplete(BookingDTO booking) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hoàn thành'),
        content: const Text('Bạn xác nhận chuyến đi đã hoàn thành?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              // Call the new API to confirm booking completion
              final success = await _bookingService.passengerConfirmCompletionDTO(booking.id);
              
              setState(() {
                _isLoading = false;
              });
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xác nhận hoàn thành chuyến đi'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadBookings(); // Refresh list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể xác nhận hoàn thành. Vui lòng thử lại sau.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }
} 