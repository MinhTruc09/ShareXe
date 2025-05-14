import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/ride.dart';
import '../../../models/booking.dart';
import '../../../services/booking_service.dart';
import '../../../services/notification_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../../../services/chat_service.dart';
import '../chat/chat_room_screen.dart';
import '../../../services/ride_service.dart';
import '../../../services/websocket_service.dart';

class RideDetailScreen extends StatefulWidget {
  final dynamic ride;

  const RideDetailScreen({Key? key, required this.ride}) : super(key: key);

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final BookingService _bookingService = BookingService();
  final NotificationService _notificationService = NotificationService();
  final RideService _rideService = RideService();
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocketService = WebSocketService();
  bool _isBooking = false;
  bool _isBooked = false;
  Booking? _booking;
  int _selectedSeats = 1;
  StreamSubscription<DatabaseEvent>? _bookingStatusSubscription;
  int _availableSeats = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _availableSeats = widget.ride.availableSeats;
    _selectedSeats = 1; // Mặc định chọn 1 ghế
    
    // Thiết lập lắng nghe tin nhắn chat qua WebSocket
    _setupChatMessageListener();
    
    // Gọi lấy dữ liệu booking khi khởi tạo màn hình
    _loadBookingData();
  }
  
  // Phương thức thiết lập lắng nghe tin nhắn WebSocket
  void _setupChatMessageListener() {
    // Đăng ký callback để nhận tin nhắn chat mới
    _webSocketService.onChatMessageReceived = (chatMessage) {
      // Kiểm tra xem người dùng có đang trong phòng chat không
      // Nếu không, hiển thị thông báo tin nhắn mới
      final Ride rideData = widget.ride as Ride;
      final String driverEmail = rideData.driverEmail ?? '';
      
      if ((chatMessage.senderEmail == driverEmail || chatMessage.receiverEmail == driverEmail) && mounted) {
        print('📩 Nhận tin nhắn mới từ tài xế: ${chatMessage.content}');
        
        // Hiển thị thông báo trên màn hình
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tin nhắn mới từ ${rideData.driverName}: ${chatMessage.content}'),
            action: SnackBarAction(
              label: 'Xem',
              onPressed: () async {
                // Mở màn hình chat
                final roomId = await _chatService.createOrGetChatRoom(driverEmail);
                if (roomId != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        roomId: roomId,
                        partnerName: rideData.driverName,
                        partnerEmail: driverEmail,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    };
  }

  // Method mới để tải dữ liệu booking
  Future<void> _loadBookingData() async {
    print('🔄 Đang tải dữ liệu booking cho chuyến đi...');
    await _checkExistingBooking();
  }

  @override
  void dispose() {
    // Hủy đăng ký callback khi widget bị hủy
    _webSocketService.onChatMessageReceived = null;
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

  // Kiểm tra xem người dùng đã đặt chỗ chuyến đi này chưa
  Future<void> _checkExistingBooking() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Bắt đầu kiểm tra booking hiện có...');
      
      // Lấy danh sách booking của người dùng
      final bookings = await _bookingService.getPassengerBookings();
      print('🔍 Lấy được ${bookings.length} bookings của người dùng');
      
      // Tìm booking cho chuyến đi hiện tại
      final Ride rideData = widget.ride as Ride;
      final int rideId = rideData.id;
      print('🔍 Đang kiểm tra chuyến đi #$rideId');
      
      // In ra danh sách tất cả rideId từ bookings
      final allRideIds = bookings.map((b) => b.rideId).toList();
      print('📋 Danh sách rideId từ tất cả bookings: $allRideIds');
      
      // Chỉ lấy booking đang hoạt động (không bị hủy hoặc từ chối)
      final activeBookings = bookings.where((booking) => 
          booking.rideId == rideId && 
          booking.status.toUpperCase() != 'CANCELLED' && 
          booking.status.toUpperCase() != 'REJECTED'
      ).toList();
      
      if (activeBookings.isNotEmpty) {
        // Nếu đã tồn tại booking đang hoạt động cho chuyến đi này
        final booking = activeBookings.first;
        print('✅ Đã tìm thấy booking đang hoạt động cho chuyến đi #$rideId: ${booking.id} - trạng thái: ${booking.status}');
        
        if (!mounted) return;
        setState(() {
          _isBooked = true;
          _booking = booking;
          
          // Set up real-time listener for this booking
          _setupBookingStatusListener(_booking!.id);
        });
      } else {
        // Kiểm tra booking gần đây nhất trong bộ nhớ local
        final lastCreatedBooking = _bookingService.getLastCreatedBooking();
        if (lastCreatedBooking != null && 
            lastCreatedBooking.rideId == rideId && 
            lastCreatedBooking.status.toUpperCase() != 'CANCELLED' && 
            lastCreatedBooking.status.toUpperCase() != 'REJECTED') {
          
          print('✅ Tìm thấy booking local cho chuyến đi #$rideId: ${lastCreatedBooking.id} - trạng thái: ${lastCreatedBooking.status}');
          
          if (!mounted) return;
          setState(() {
            _isBooked = true;
            _booking = lastCreatedBooking;
            
            // Set up real-time listener for this booking
            _setupBookingStatusListener(_booking!.id);
          });
        } else {
          print('ℹ️ Không có booking đang hoạt động nào cho chuyến đi #$rideId');
          if (!mounted) return;
          setState(() {
            // Đảm bảo rằng _isBooked được đặt thành false nếu không tìm thấy booking
            _isBooked = false;
            _booking = null;
          });
        }
      }
    } catch (e) {
      print('❌ Lỗi khi kiểm tra booking hiện có: $e');
      if (!mounted) return;
      setState(() {
        _isBooked = false;
        _booking = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Set up real-time listener for booking status
  void _setupBookingStatusListener(int bookingId) {
    // Cancel any existing subscription first
    _bookingStatusSubscription?.cancel();
    
    final DatabaseReference bookingRef = FirebaseDatabase.instance.ref(
      'bookings/$bookingId',
    );

    print('🔄 Thiết lập Firebase listener cho booking #$bookingId');
    
    // First check if booking already exists in Firebase
    bookingRef.get().then((snapshot) {
      if (snapshot.exists) {
        print('✅ Booking #$bookingId đã tồn tại trên Firebase');
        
        try {
          // Update local data if needed
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          final firebaseBooking = Booking.fromJson(data);
          print('📡 Dữ liệu Firebase hiện tại: ${firebaseBooking.status}');
          
          // Update local state if Firebase has more recent status
          if (_booking?.status != firebaseBooking.status) {
            print('ℹ️ Cập nhật trạng thái local từ Firebase: ${_booking?.status} -> ${firebaseBooking.status}');
            setState(() {
              _booking = firebaseBooking;
            });
          }
        } catch (e) {
          print('⚠️ Lỗi khi đọc dữ liệu booking từ Firebase: $e');
        }
      } else {
        print('ℹ️ Booking #$bookingId chưa tồn tại trên Firebase, đang tạo mới...');
        // Save current booking data to Firebase
        bookingRef.set(_booking!.toJson()).then((_) {
          print('✅ Đã lưu thông tin booking #$bookingId lên Firebase');
        }).catchError((error) {
          print('❌ Lỗi khi lưu booking lên Firebase: $error');
        });
      }
    }).catchError((error) {
      print('❌ Lỗi khi kiểm tra booking trên Firebase: $error');
    });
    
    // Set up listener for real-time updates
    _bookingStatusSubscription = bookingRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final updatedBooking = Booking.fromJson(data);
          print('📡 Nhận được cập nhật từ Firebase cho booking #$bookingId - trạng thái: ${updatedBooking.status}');

          setState(() {
            _booking = updatedBooking;
          });

          // Show notification if status changed to APPROVED
          if (updatedBooking.status.toUpperCase() == 'APPROVED') {
            _showDriverAcceptedDialog(updatedBooking);
          }
        } catch (e) {
          print('❌ Lỗi khi xử lý dữ liệu booking từ Firebase: $e');
        }
      } else {
        print('⚠️ Không tìm thấy dữ liệu booking #$bookingId trên Firebase');
      }
    }, onError: (error) {
      print('❌ Lỗi khi lắng nghe cập nhật từ Firebase: $error');
    });
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

  Future<void> _showBookingSuccessDialog(Booking booking) async {
    // Thay vì showDialog, dùng await showDialog để đợi cho đến khi dialog đóng
    return showDialog(
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final Ride rideData = widget.ride as Ride;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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

            // Details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver info
                  const Text(
                    'Thông tin tài xế',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          icon: const Icon(
                            Icons.message,
                            color: Color(0xFF00AEEF),
                          ),
                          onPressed: () async {
                            try {
                              // Lấy hoặc tạo phòng chat với tài xế
                              final roomId = await _chatService
                                  .createOrGetChatRoom(rideData.driverEmail);

                              if (roomId != null && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChatRoomScreen(
                                          roomId: roomId,
                                          partnerName: rideData.driverName,
                                          partnerEmail: rideData.driverEmail,
                                        ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Không thể tạo phòng chat, vui lòng thử lại sau',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.phone,
                            color: Color(0xFF00AEEF),
                          ),
                          onPressed: () {
                            // Implement call driver
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tính năng đang phát triển'),
                              ),
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

                  // Action Buttons Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _isBooked
                            ? _buildBookingStatusContainer(_booking!)
                            : rideData.status.toUpperCase() == 'ACTIVE'
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Số ghế',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _availableSeats > 0
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.remove),
                                                        onPressed: _selectedSeats > 1
                                                            ? () {
                                                                setState(() {
                                                                  _selectedSeats--;
                                                                });
                                                              }
                                                            : null,
                                                      ),
                                                      Text(
                                                        '$_selectedSeats',
                                                        style:
                                                            const TextStyle(fontSize: 18),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.add),
                                                        onPressed: _selectedSeats <
                                                                _availableSeats
                                                            ? () {
                                                                setState(() {
                                                                  _selectedSeats++;
                                                                });
                                                              }
                                                            : null,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  'Còn ${_availableSeats} ghế',
                                                  style: TextStyle(
                                                    color: _availableSeats <= 2
                                                        ? Colors.red
                                                        : Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              'Đã hết ghế',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tổng tiền: ${currencyFormat.format(_selectedSeats * (rideData.pricePerSeat ?? 0))}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00AEEF),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: _isBooking ? null : _bookRide,
                                        child: _isBooking
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Đặt chỗ',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.orange.shade800,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Chuyến đi không khả dụng',
                                                style: TextStyle(
                                                  color: Colors.orange.shade800,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Chuyến đi này hiện không cho phép đặt chỗ. Trạng thái hiện tại: ${rideData.status}',
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
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

  Future<void> _bookRide() async {
    final Ride rideData = widget.ride as Ride;

    setState(() {
      _isBooking = true;
    });

    try {
      print('🛒 Bắt đầu đặt chỗ cho chuyến đi #${rideData.id} với ${_selectedSeats} ghế');
      final booking = await _bookingService.bookRide(
        rideData.id,
        _selectedSeats,
      );

      if (booking != null) {
        print('✅ Đặt chỗ thành công cho chuyến đi #${rideData.id}, booking ID: ${booking.id}');
        
        setState(() {
          _isBooking = false;
          _isBooked = true;
          _booking = booking;
        });

        // Gửi thông báo cho tài xế về yêu cầu đặt chỗ mới
        try {
          // Trích xuất thông tin tài xế từ ride nếu có
          final String driverEmail = rideData.driverEmail ?? '';
          
          if (driverEmail.isNotEmpty) {
            await _notificationService.sendBookingRequestNotification(
              booking.id,
              booking.rideId,
              booking.passengerName,
              driverEmail
            );
            
            // Tự động tạo phòng chat và gửi tin nhắn chào mừng
            await _createChatRoomWithDriver(driverEmail);
          } else {
            print('⚠️ Không thể gửi thông báo: Thiếu email tài xế');
          }
        } catch (e) {
          print('❌ Lỗi khi gửi thông báo đặt chỗ: $e');
          // Không dừng quy trình vì đây không phải lỗi chính
        }

        // Set up real-time listener for this booking
        _setupBookingStatusListener(booking.id);
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt chỗ thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Đợi 1 giây để hiển thị thông báo
        await Future.delayed(const Duration(seconds: 1));
        
        // Quay về màn hình trước đó với kết quả true để làm mới danh sách
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _isBooking = false;
        });
        print('❌ Không nhận được đối tượng booking từ API');
        
        // Hiển thị thông báo lỗi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt chỗ không thành công. Vui lòng thử lại sau.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isBooking = false;
      });
      print('❌ Lỗi khi đặt chỗ: $e');
      
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget hiển thị trạng thái booking
  Widget _buildBookingStatusContainer(Booking booking) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    final Ride rideData = widget.ride as Ride;
    // Check if the ride is ready for departure
    final bool isReadyForDeparture = _rideService.canConfirmRide(rideData);
    // Check if the ride is in progress and ready for completion
    final bool isInProgress = rideData.status.toUpperCase() == 'IN_PROGRESS';
    // Check if the driver has confirmed the ride is complete
    final bool isDriverConfirmed = rideData.status.toUpperCase() == 'DRIVER_CONFIRMED';
    // Ride needs completion if it's in the IN_PROGRESS status
    final bool needsCompletion = isInProgress;
    // Passenger needs to confirm completion if driver has confirmed
    final bool needsPassengerConfirmation = isDriverConfirmed;
    
    switch (booking.status.toUpperCase()) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'Đang chờ tài xế xác nhận';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'APPROVED':
      case 'ACCEPTED':
        if (rideData.status.toUpperCase() == 'DRIVER_CONFIRMED') {
          statusColor = Colors.teal;
          statusText = 'Tài xế đã xác nhận hoàn thành';
          statusIcon = Icons.verified;
        } else {
          statusColor = Colors.green;
          statusText = 'Đã được tài xế xác nhận';
          statusIcon = Icons.check_circle;
        }
        break;
      case 'COMPLETED':
        statusColor = Colors.blue;
        statusText = 'Chuyến đi đã hoàn thành';
        statusIcon = Icons.star;
        break;
      case 'CANCELLED':
      case 'REJECTED':
        statusColor = Colors.red;
        statusText = 'Đã bị hủy/từ chối';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Trạng thái không xác định';
        statusIcon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBookingDetailItem('Mã đặt chỗ:', '#${booking.id}'),
          _buildBookingDetailItem('Số ghế đã đặt:', '${booking.seatsBooked}'),
          _buildBookingDetailItem(
            'Tổng tiền:',
            booking.pricePerSeat != null
                ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                    .format(booking.pricePerSeat! * booking.seatsBooked)
                : 'Không có thông tin',
          ),
          _buildBookingDetailItem(
            'Thời gian đặt:',
            _formatTime(booking.createdAt),
          ),
          
          // Thêm nút chat với tài xế
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final Ride rideData = widget.ride as Ride;
                  final String driverEmail = rideData.driverEmail ?? '';
                  
                  if (driverEmail.isNotEmpty) {
                    // Mở màn hình chat với tài xế
                    final roomId = await _chatService.createOrGetChatRoom(driverEmail);
                    if (roomId != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen(
                            roomId: roomId,
                            partnerName: rideData.driverName,
                            partnerEmail: driverEmail,
                          ),
                        ),
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không thể tạo phòng chat, vui lòng thử lại sau'),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Nhắn tin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Xử lý chức năng gọi điện (sẽ thêm sau)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang phát triển'),
                    ),
                  );
                },
                icon: const Icon(Icons.phone),
                label: const Text('Gọi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          // Departure confirmation for rides in progress
          if (isReadyForDeparture && (booking.status.toUpperCase() == 'APPROVED' || booking.status.toUpperCase() == 'ACCEPTED'))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Hãy xác nhận khi bạn đã sẵn sàng tham gia chuyến đi này.',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _confirmPassengerDeparture(booking),
                        icon: _isLoading
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
                          _isLoading ? 'Đang xác nhận...' : 'Xác nhận tham gia'
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Ride completion confirmation for passenger when ride is in progress
          if (needsCompletion && (booking.status.toUpperCase() == 'APPROVED' || booking.status.toUpperCase() == 'ACCEPTED'))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
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
                      'Hãy xác nhận khi bạn đã đến nơi và hoàn thành chuyến đi này.',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _confirmRideCompletion(booking),
                        icon: _isLoading
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
                          _isLoading ? 'Đang xác nhận...' : 'Xác nhận đã đến nơi'
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
            ),
          
          // Passenger confirmation of ride completion when driver has confirmed
          if (needsPassengerConfirmation && (booking.status.toUpperCase() == 'APPROVED' || booking.status.toUpperCase() == 'ACCEPTED'))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.teal.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tài xế đã xác nhận hoàn thành!',
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tài xế đã xác nhận chuyến đi đã hoàn thành. Vui lòng kiểm tra và xác nhận để hoàn tất chuyến đi.',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _confirmRideCompletion(booking),
                        icon: _isLoading
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
                          _isLoading ? 'Đang xác nhận...' : 'Xác nhận hoàn thành'
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Hiển thị nút hủy đặt chỗ nếu đang ở trạng thái chờ xác nhận
          if (booking.status.toUpperCase() == 'PENDING')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _cancelBooking(booking),
                  child: const Text(
                    'Hủy đặt chỗ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Hàm hủy đặt chỗ
  Future<void> _cancelBooking(Booking booking) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đặt chỗ không?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hủy đặt chỗ'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Hiển thị loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      print('🚫 Bắt đầu hủy đặt chỗ cho booking #${booking.id}');
      
      // Gọi API để hủy booking sử dụng endpoint mới
      final success = await _bookingService.cancelBooking(booking.rideId);
      
      if (success) {
        print('✅ Hủy đặt chỗ thành công');
        
        // Xóa thông tin booking khỏi Firebase để đảm bảo không còn dữ liệu cũ
        try {
          final DatabaseReference bookingRef = FirebaseDatabase.instance.ref('bookings/${booking.id}');
          await bookingRef.remove();
          print('✅ Đã xóa booking #${booking.id} khỏi Firebase');
          
          // Đảm bảo hủy subscription hiện tại
          _bookingStatusSubscription?.cancel();
          _bookingStatusSubscription = null;
        } catch (e) {
          print('⚠️ Lỗi khi xóa booking khỏi Firebase: $e');
          // Không dừng quy trình vì đây không phải lỗi chính
        }
        
        if (mounted) {
          // Cập nhật trạng thái booking locally để hiển thị trạng thái "Đã hủy"
          setState(() {
            _booking = null;  // Xóa booking hoàn toàn thay vì chỉ cập nhật trạng thái
            _isBooked = false;  // Đặt lại trạng thái là chưa đặt
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã hủy đặt chỗ thành công'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Đợi 2 giây để hiển thị trạng thái đã hủy trước khi quay lại màn hình trước
          await Future.delayed(const Duration(seconds: 2));
          
          // Force xóa cache để load lại danh sách chuyến đi có sẵn
          final rideService = RideService();
          rideService.clearAvailableRidesCache();
          
          // Đặt kết quả và quay về màn hình trước đó
          // Giá trị true sẽ trigger việc refresh danh sách chuyến đi trên màn hình trước
          if (mounted) {
            Navigator.pop(context, true);
          }
        }
      } else {
        print('❌ Không thể hủy đặt chỗ qua API');
        
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể hủy đặt chỗ. Vui lòng thử lại sau.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi khi hủy đặt chỗ: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBookingDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Hành khách xác nhận tham gia chuyến đi
  Future<void> _confirmPassengerDeparture(Booking booking) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận tham gia'),
        content: const Text('Bạn xác nhận đã sẵn sàng tham gia chuyến đi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy thông tin về ride ID 
      final rideId = booking.rideId;
      
      // Xác nhận tham gia chuyến đi
      final success = await _rideService.passengerConfirmDeparture(rideId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (success) {
          // Reload booking data
          _refreshBookingStatus();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xác nhận tham gia chuyến đi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xác nhận tham gia chuyến đi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hành khách xác nhận hoàn thành chuyến đi
  Future<void> _confirmRideCompletion(Booking booking) async {
    final Ride rideData = widget.ride as Ride;
    final String rideStatus = rideData.status.toUpperCase();
    final bool isDriverConfirmed = rideStatus == 'DRIVER_CONFIRMED';
    
    // Hiển thị thông báo khác nhau dựa trên trạng thái chuyến đi
    String dialogTitle = isDriverConfirmed 
        ? 'Xác nhận hoàn thành chuyến đi' 
        : 'Xác nhận đã đến nơi';
        
    String dialogContent = isDriverConfirmed
        ? 'Tài xế đã xác nhận chuyến đi hoàn thành. Bạn đồng ý xác nhận hoàn thành?'
        : 'Bạn xác nhận đã hoàn thành chuyến đi này?';
    
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDriverConfirmed ? Colors.teal : Colors.green,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy thông tin về ride ID 
      final rideId = booking.rideId;
      
      // Xác nhận hoàn thành chuyến đi - sử dụng phương thức phù hợp dựa trên trạng thái
      final success = await _rideService.passengerConfirmCompletion(rideId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (success) {
          // Reload booking data
          _refreshBookingStatus();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDriverConfirmed 
                  ? 'Đã xác nhận hoàn thành chuyến đi' 
                  : 'Đã xác nhận đã đến nơi'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isDriverConfirmed 
                  ? 'Không thể xác nhận hoàn thành chuyến đi' 
                  : 'Không thể xác nhận đã đến nơi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hàm để tải lại thông tin booking khi có thay đổi
  Future<void> _refreshBookingStatus() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Nếu người dùng đã đặt chỗ cho chuyến đi này
      if (_isBooked && _booking != null) {
        // Lấy booking mới nhất
        final latestBooking = await _bookingService.getBookingDetail(_booking!.id);
        
        if (latestBooking != null) {
          setState(() {
            _booking = latestBooking;
            _isLoading = false;
          });
        } else {
          // Có thể booking đã bị xóa
          setState(() {
            _isBooked = false;
            _booking = null;
            _isLoading = false;
          });
        }
      } else {
        // Kiểm tra xem người dùng đã có booking nào cho chuyến đi này chưa
        final Ride rideData = widget.ride as Ride;
        final bookings = await _bookingService.getPassengerBookings();
        final currentBooking = bookings.where((b) => b.rideId == rideData.id).firstOrNull;
        
        if (currentBooking != null) {
          setState(() {
            _isBooked = true;
            _booking = currentBooking;
            _isLoading = false;
          });
          
          // Set up real-time listener for this booking
          _setupBookingStatusListener(currentBooking.id);
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Lỗi khi tải thông tin booking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Phương thức mới để tự động tạo phòng chat với tài xế sau khi đặt chỗ thành công
  Future<void> _createChatRoomWithDriver(String driverEmail) async {
    try {
      if (driverEmail.isEmpty) {
        print('⚠️ Không thể tạo phòng chat: Email tài xế trống');
        return;
      }
      
      print('🔄 Đang tạo phòng chat với tài xế: $driverEmail');
      
      // Tạo hoặc lấy phòng chat với tài xế
      final roomId = await _chatService.createOrGetChatRoom(driverEmail);
      
      if (roomId != null && roomId.isNotEmpty) {
        print('✅ Đã tạo/lấy phòng chat thành công: $roomId');
        
        // Đảm bảo phòng chat được hiển thị cho cả hai bên
        await _chatService.ensureChatRoomIsCreated(driverEmail);
        
        // Gửi tin nhắn tự động thông báo về booking
        if (_booking != null) {
          final bookingInfo = 'Xin chào! Tôi đã đặt ${_booking!.seatsBooked} ghế cho chuyến đi của bạn!';
          final messageSent = await _chatService.sendMessage(roomId, driverEmail, bookingInfo);
          
          if (messageSent) {
            print('✅ Đã gửi tin nhắn chào mừng thông qua phòng chat: $roomId');
          } else {
            print('⚠️ Không thể gửi tin nhắn chào mừng');
          }
        }
      } else {
        print('⚠️ Không thể tạo/lấy phòng chat');
      }
    } catch (e) {
      print('❌ Lỗi khi tạo phòng chat với tài xế: $e');
    }
  }
}
