import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'dart:math';
import '../../../models/booking.dart';
import '../../../services/booking_service.dart';
import '../../../utils/app_config.dart';
import '../../../utils/api_debug_helper.dart';

class DriverBookingsScreen extends StatefulWidget {
  const DriverBookingsScreen({Key? key}) : super(key: key);

  @override
  State<DriverBookingsScreen> createState() => _DriverBookingsScreenState();
}

class _DriverBookingsScreenState extends State<DriverBookingsScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  final AppConfig _appConfig = AppConfig();
  final ApiDebugHelper _apiDebugHelper = ApiDebugHelper();
  late TabController _tabController;
  
  List<Booking> _pendingBookings = [];
  List<Booking> _acceptedBookings = [];
  List<Booking> _completedBookings = [];
  List<Booking> _ongoingBookings = [];
  List<Booking> _cancelledBookings = [];
  
  bool _isLoading = false;
  bool _isUsingMockData = false;
  bool _isDebugMode = false;
  String _apiResponse = '';
  int _apiCallAttempts = 0;
  DateTime _lastRefreshTime = DateTime.now();

  // Quick statistics
  int get _totalBookings => _pendingBookings.length + _acceptedBookings.length + 
                           _ongoingBookings.length + _completedBookings.length + 
                           _cancelledBookings.length;
  
  int get _totalSeatsBooked {
    int sum = 0;
    for (var booking in _pendingBookings) sum += booking.seatsBooked;
    for (var booking in _acceptedBookings) sum += booking.seatsBooked;
    for (var booking in _ongoingBookings) sum += booking.seatsBooked;
    for (var booking in _completedBookings) sum += booking.seatsBooked;
    return sum;
  }
  
  double get _totalRevenue => _completedBookings
      .map((b) => (b.pricePerSeat ?? 0.0) * b.seatsBooked)
      .fold(0.0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleDebugMode() {
    setState(() {
      _isDebugMode = !_isDebugMode;
    });
    
    if (_isDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã bật chế độ debug')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tắt chế độ debug')),
      );
    }
  }

  void _updateApiUrl() {
    _apiDebugHelper.showUpdateApiUrlDialog(
      context,
      onUpdated: _loadBookings,
    );
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _apiResponse = '';
      _apiCallAttempts++;
    });

    try {
      developer.log('Bắt đầu tải danh sách booking của tài xế...', name: 'driver_bookings');
      developer.log('API Base URL: ${_appConfig.fullApiUrl}', name: 'driver_bookings');
      
      final stopwatch = Stopwatch()..start();
      final bookings = await _bookingService.getBookingsForDriver();
      stopwatch.stop();
      
      // Improved detection logic for real vs mock data
      bool isRealData = false;
      
      if (bookings.isNotEmpty) {
        // Check for real API data characteristics
        // 1. In our app, mock data IDs are typically over 100 with hardcoded values
        // 2. Real bookings likely have more detailed data and will vary more
        // 3. We can also check for booking.rideId patterns as well
        
        isRealData = bookings.any((booking) => 
            // Any non-hardcoded ID pattern suggests real data
            (booking.id < 100 && booking.id > 0) || 
            // Real data often has diverse rideIds  
            (booking.rideId > 0 && booking.rideId < 1000) ||
            // Real API data typically has more populated fields
            (booking.passengerId > 0 && booking.departure != null && booking.destination != null)
        );
        
        // Log detection details for debugging
        developer.log('Data detection - First booking:', name: 'driver_bookings');
        if (bookings.isNotEmpty) {
          final firstBooking = bookings.first;
          developer.log('  ID: ${firstBooking.id}, RideID: ${firstBooking.rideId}, PassengerID: ${firstBooking.passengerId}', 
              name: 'driver_bookings');
          developer.log('  Status: ${firstBooking.status}, Fields filled: ${_countFilledFields(firstBooking)}', 
              name: 'driver_bookings');
        }
      }
      
      // Cập nhật trạng thái dữ liệu mẫu
      setState(() {
        _isUsingMockData = !isRealData;
        _apiResponse = !isRealData 
            ? 'Đang sử dụng dữ liệu mẫu. Không thể kết nối đến API thực. Đã cố gắng $_apiCallAttempts lần.'
            : 'Đã lấy ${bookings.length} booking từ API trong ${stopwatch.elapsedMilliseconds}ms';
        _lastRefreshTime = DateTime.now();
      });
      
      // Log thêm thông tin để debug
      if (bookings.isNotEmpty) {
        developer.log('ID của một số booking đầu tiên:', name: 'driver_bookings');
        for (int i = 0; i < min(5, bookings.length); i++) {
          developer.log('   Booking #${i+1}: ID=${bookings[i].id}, RideID=${bookings[i].rideId}, Status=${bookings[i].status}', 
              name: 'driver_bookings');
        }
      }

      // Phân loại bookings dựa trên trạng thái
      final pending = <Booking>[];
      final accepted = <Booking>[];
      final ongoing = <Booking>[];
      final completed = <Booking>[];
      final cancelled = <Booking>[];

      for (var booking in bookings) {
        final status = booking.status.toUpperCase();
        if (status == 'PENDING') {
          pending.add(booking);
        } else if (status == 'ACCEPTED' || status == 'APPROVED') {
          accepted.add(booking);
        } else if (status == 'IN_PROGRESS' || status == 'ONGOING' || status == 'DRIVER_CONFIRMED') {
          ongoing.add(booking);
        } else if (status == 'COMPLETED' || status == 'DONE' || status == 'PASSENGER_CONFIRMED') {
          completed.add(booking);
        } else if (status == 'CANCELLED' || status == 'REJECTED' || status == 'CANCEL') {
          cancelled.add(booking);
        } else {
          // Fallback for unknown status
          developer.log('Booking #${booking.id} has unknown status: $status', name: 'driver_bookings');
          pending.add(booking); // Default to pending
        }
      }

      if (mounted) {
        setState(() {
          _pendingBookings = pending;
          _acceptedBookings = accepted;
          _ongoingBookings = ongoing;
          _completedBookings = completed;
          _cancelledBookings = cancelled;
          _isLoading = false;
        });

        developer.log('Phân loại booking:', name: 'driver_bookings');
        developer.log('- Chờ duyệt: ${_pendingBookings.length}', name: 'driver_bookings');
        developer.log('- Đã chấp nhận: ${_acceptedBookings.length}', name: 'driver_bookings');
        developer.log('- Đang tiến hành: ${_ongoingBookings.length}', name: 'driver_bookings');
        developer.log('- Hoàn thành: ${_completedBookings.length}', name: 'driver_bookings');
        developer.log('- Đã hủy/từ chối: ${_cancelledBookings.length}', name: 'driver_bookings');
      }
    } catch (e) {
      developer.log('Lỗi khi tải danh sách booking: $e', name: 'driver_bookings', error: e);
      
      setState(() {
        _apiResponse = 'Lỗi: $e';
        _isUsingMockData = true;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải danh sách booking: $e')),
        );
      }
    }
  }
  
  // Helper to count non-null fields in a booking
  int _countFilledFields(Booking booking) {
    int count = 0;
    if (booking.id > 0) count++;
    if (booking.rideId > 0) count++;
    if (booking.passengerId > 0) count++;
    if (booking.status.isNotEmpty) count++;
    if (booking.passengerName != null && booking.passengerName.isNotEmpty) count++;
    if (booking.createdAt.isNotEmpty) count++;
    if (booking.departure != null && booking.departure!.isNotEmpty) count++;
    if (booking.destination != null && booking.destination!.isNotEmpty) count++;
    if (booking.pricePerSeat != null && booking.pricePerSeat! > 0) count++;
    if (booking.totalPrice != null && booking.totalPrice! > 0) count++;
    if (booking.startTime != null && booking.startTime!.isNotEmpty) count++;
    return count;
  }

  Widget _buildDebugPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isUsingMockData ? Icons.warning : Icons.check_circle,
                color: _isUsingMockData ? Colors.orange : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isUsingMockData 
                      ? 'Đang sử dụng dữ liệu mẫu - Không có dữ liệu thực từ API' 
                      : 'Đang sử dụng dữ liệu thực từ API',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'API URL: ${_appConfig.fullApiUrl}/driver/bookings',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Cập nhật: ${DateFormat('HH:mm:ss').format(_lastRefreshTime)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (_apiResponse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _apiResponse,
                style: TextStyle(
                  color: _isUsingMockData ? Colors.orange : Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 4),
          // Statistics row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Tổng', _totalBookings.toString()),
                _buildStatItem('Chờ duyệt', _pendingBookings.length.toString()),
                _buildStatItem('Đã chấp nhận', _acceptedBookings.length.toString()),
                _buildStatItem('Đang tiến hành', _ongoingBookings.length.toString()),
                _buildStatItem('Hoàn thành', _completedBookings.length.toString()),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Connection diagnostic info
          if (_isUsingMockData)
            Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lỗi kết nối:',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Endpoint: /driver/bookings',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    'Attempts: $_apiCallAttempts',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const Text(
                    'Kiểm tra: 1) API đang chạy 2) URL chính xác 3) Token hợp lệ',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh, size: 14, color: Colors.white),
                label: const Text(
                  'Làm mới',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _updateApiUrl,
                icon: const Icon(Icons.link, size: 14, color: Colors.white),
                label: const Text(
                  'Đổi URL',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D72),
        title: const Text('Chuyến đi của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _toggleDebugMode,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Chờ duyệt (${_pendingBookings.length})'),
            Tab(text: 'Đã chấp nhận (${_acceptedBookings.length})'),
            Tab(text: 'Đang tiến hành (${_ongoingBookings.length})'),
            Tab(text: 'Hoàn thành (${_completedBookings.length})'),
            Tab(text: 'Đã hủy (${_cancelledBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isDebugMode) _buildDebugPanel(),
                
                // Statistics panel
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Tổng số',
                        _totalBookings.toString(),
                        Icons.book_online,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Ghế đã đặt',
                        _totalSeatsBooked.toString(),
                        Icons.airline_seat_recline_normal,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Doanh thu',
                        NumberFormat('#,###', 'vi_VN').format(_totalRevenue) + ' đ',
                        Icons.monetization_on,
                        Colors.amber,
                      ),
                    ],
                  ),
                ),
                
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(_pendingBookings, BookingStatus.pending),
                      _buildBookingsList(_acceptedBookings, BookingStatus.accepted),
                      _buildBookingsList(_ongoingBookings, BookingStatus.ongoing),
                      _buildBookingsList(_completedBookings, BookingStatus.completed),
                      _buildBookingsList(_cancelledBookings, BookingStatus.cancelled),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBookingsList(List<Booking> bookings, BookingStatus status) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(status),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            if (status == BookingStatus.pending)
              TextButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới danh sách'),
              ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        itemCount: bookings.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, status);
        },
      ),
    );
  }
  
  String _getEmptyStateMessage(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Không có yêu cầu đặt chỗ nào đang chờ duyệt';
      case BookingStatus.accepted:
        return 'Không có yêu cầu đặt chỗ nào đã được chấp nhận';
      case BookingStatus.ongoing:
        return 'Không có chuyến đi nào đang tiến hành';
      case BookingStatus.completed:
        return 'Không có chuyến đi nào đã hoàn thành';
      case BookingStatus.cancelled:
        return 'Không có chuyến đi nào đã bị hủy hoặc từ chối';
    }
  }
  
  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.hourglass_empty;
      case BookingStatus.accepted:
        return Icons.check_circle_outline;
      case BookingStatus.ongoing:
        return Icons.directions_car;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
  
  Widget _buildBookingCard(Booking booking, BookingStatus status) {
    final double totalPrice = booking.pricePerSeat != null 
      ? booking.pricePerSeat! * booking.seatsBooked
      : 0.0;
    final formattedPrice = NumberFormat('#,###', 'vi_VN').format(totalPrice);
    final formattedDate = _formatDateTime(booking.startTime.toString());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đặt chỗ #${booking.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          
          // Booking details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hành khách: ${booking.passengerName}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.route, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${booking.departure} → ${booking.destination}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.airline_seat_recline_normal, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.seatsBooked} ghế',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$formattedPrice đ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                
                // Action buttons based on status
                const SizedBox(height: 16),
                if (status == BookingStatus.pending)
                  _buildActionButtons(booking, status)
                else if (status == BookingStatus.accepted)
                  _buildActionButtons(booking, status)
                else if (status == BookingStatus.ongoing)
                  _buildActionButtons(booking, status)
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.accepted:
        return Colors.blue;
      case BookingStatus.ongoing:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.purple;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }
  
  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Chờ duyệt';
      case BookingStatus.accepted:
        return 'Đã chấp nhận';
      case BookingStatus.ongoing:
        return 'Đang tiến hành';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã hủy/từ chối';
    }
  }
  
  Widget _buildActionButtons(Booking booking, BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => _rejectBooking(booking),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Từ chối'),
            ),
            ElevatedButton(
              onPressed: () => _acceptBooking(booking),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Chấp nhận'),
            ),
          ],
        );
      case BookingStatus.accepted:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => _cancelBooking(booking),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => _startTrip(booking),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Bắt đầu chuyến đi'),
            ),
          ],
        );
      case BookingStatus.ongoing:
        return Center(
          child: ElevatedButton(
            onPressed: () => _completeTrip(booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Hoàn thành chuyến đi'),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
  
  Future<void> _acceptBooking(Booking booking) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      developer.log('Accepting booking #${booking.id}...', name: 'driver_bookings');
      
      // Use the booking service to accept the booking
      final success = await _bookingService.driverAcceptBookingDTO(booking.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chấp nhận yêu cầu đặt chỗ thành công'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data after action
        _loadBookings();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể chấp nhận yêu cầu. Vui lòng thử lại sau.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error accepting booking: $e', name: 'driver_bookings', error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _rejectBooking(Booking booking) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      developer.log('Rejecting booking #${booking.id}...', name: 'driver_bookings');
      
      // Use the booking service to reject the booking
      final success = await _bookingService.driverRejectBookingDTO(booking.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã từ chối yêu cầu đặt chỗ'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // Reload data after action
        _loadBookings();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể từ chối yêu cầu. Vui lòng thử lại sau.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error rejecting booking: $e', name: 'driver_bookings', error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _cancelBooking(Booking booking) async {
    // To be implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hủy yêu cầu đặt chỗ')),
    );
    
    // Reload data after action
    _loadBookings();
  }
  
  Future<void> _startTrip(Booking booking) async {
    // To be implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã bắt đầu chuyến đi')),
    );
    
    // Reload data after action
    _loadBookings();
  }
  
  Future<void> _completeTrip(Booking booking) async {
    // To be implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã hoàn thành chuyến đi')),
    );
    
    // Reload data after action
    _loadBookings();
  }
  
  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }
}

enum BookingStatus {
  pending,
  accepted,
  ongoing,
  completed,
  cancelled,
}
