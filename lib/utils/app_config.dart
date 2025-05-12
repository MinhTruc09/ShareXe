import 'dart:io';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // API Base URL - Primary URL (Ngrok)
  String apiBaseUrl = 'https://ec9c-58-186-196-182.ngrok-free.app';
  
  // Fallback API URL - Secondary URL when Ngrok is down
  String fallbackApiUrl = 'https://sharexe-api.onrender.com';
  
  // Flag to indicate if using fallback URL
  bool isUsingFallback = false;

  // API Base Path - Đường dẫn API cơ sở
  String apiBasePath = '/api';

  // Full API URL (apiBaseUrl + apiBasePath)
  String get fullApiUrl => '${isUsingFallback ? fallbackApiUrl : apiBaseUrl}$apiBasePath';

  // WebSocket URL
  String get webSocketUrl {
    String baseUrl = isUsingFallback ? fallbackApiUrl : apiBaseUrl;
    
    // Remove any port specification with :0
    if (baseUrl.contains(':0')) {
      baseUrl = baseUrl.replaceAll(':0', '');
    }
    
    // Ensure baseUrl doesn't end with a slash
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    // Convert HTTP/HTTPS to WebSocket protocol
    String wsUrl;
    if (baseUrl.startsWith('https://')) {
      wsUrl = baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      wsUrl = baseUrl.replaceFirst('http://', 'ws://');
    } else {
      // If no protocol specified, default to secure WebSocket
      wsUrl = 'wss://$baseUrl';
    }
    
    // For Ngrok URLs, use specific WebSocket endpoint path 
    // Check if using Ngrok (containing ngrok in URL)
    if (baseUrl.contains('ngrok')) {
      return '$wsUrl/ws/websocket'; // Correct endpoint for Ngrok WebSocket
    } else {
      return '$wsUrl/ws'; // Regular WebSocket endpoint
    }
  }

  // FCM server key
  String fcmServerKey = 'YOUR_FCM_SERVER_KEY';

  // FCM topics
  String fcmTopicAllUsers = 'all_users';
  String fcmTopicDrivers = 'drivers';
  String fcmTopicPassengers = 'passengers';

  // Notification settings
  int notificationAutoDeleteDays = 30; // Thông báo tự động xóa sau 30 ngày

  // Chat settings
  int chatHistoryLimit = 50; // Số lượng tin nhắn tải mỗi lần

  // Ride status constants - Chuẩn hóa theo yêu cầu
  static const String RIDE_STATUS_ACTIVE = "ACTIVE";           // Chuyến đi sắp tới (chưa bắt đầu)
  static const String RIDE_STATUS_DRIVER_CONFIRMED = "DRIVER_CONFIRMED";  // Tài xế xác nhận hoàn thành
  static const String RIDE_STATUS_COMPLETED = "COMPLETED";     // Cả tài xế và hành khách đều xác nhận
  static const String RIDE_STATUS_CANCELLED = "CANCELLED";     // Chuyến đi bị hủy
  
  // Booking status constants - Chuẩn hóa theo yêu cầu
  static const String BOOKING_STATUS_PENDING = "PENDING";      // Vừa đặt
  static const String BOOKING_STATUS_ACCEPTED = "ACCEPTED";    // Đã được duyệt
  static const String BOOKING_STATUS_IN_PROGRESS = "IN_PROGRESS"; // Đang diễn ra
  static const String BOOKING_STATUS_PASSENGER_CONFIRMED = "PASSENGER_CONFIRMED"; // Hành khách xác nhận
  static const String BOOKING_STATUS_DRIVER_CONFIRMED = "DRIVER_CONFIRMED";       // Tài xế xác nhận
  static const String BOOKING_STATUS_COMPLETED = "COMPLETED";  // Hoàn thành
  static const String BOOKING_STATUS_CANCELLED = "CANCELLED";  // Đã hủy
  static const String BOOKING_STATUS_REJECTED = "REJECTED";    // Bị từ chối
  
  // Time buffer in minutes to determine if a ride is about to start
  int rideStartTimeBuffer = 5; // 5 minutes buffer

  // Notification types - Các loại thông báo
  // Thông báo liên quan đến booking
  static const String NOTIFICATION_BOOKING_REQUEST = "BOOKING_REQUEST";       // Có người đặt chỗ mới
  static const String NOTIFICATION_BOOKING_ACCEPTED = "BOOKING_ACCEPTED";     // Tài xế chấp nhận booking
  static const String NOTIFICATION_BOOKING_REJECTED = "BOOKING_REJECTED";     // Tài xế từ chối booking
  static const String NOTIFICATION_BOOKING_CANCELLED = "BOOKING_CANCELLED";   // Hành khách hủy booking
  
  // Thông báo liên quan đến chuyến đi
  static const String NOTIFICATION_RIDE_CREATED = "RIDE_CREATED";            // Tài xế tạo chuyến đi mới
  static const String NOTIFICATION_RIDE_STARTED = "RIDE_STARTED";            // Chuyến đi bắt đầu
  static const String NOTIFICATION_DRIVER_CONFIRMED = "DRIVER_CONFIRMED";    // Tài xế xác nhận hoàn thành
  static const String NOTIFICATION_PASSENGER_CONFIRMED = "PASSENGER_CONFIRMED"; // Hành khách xác nhận hoàn thành
  static const String NOTIFICATION_RIDE_COMPLETED = "RIDE_COMPLETED";        // Chuyến đi hoàn thành
  static const String NOTIFICATION_RIDE_CANCELLED = "RIDE_CANCELLED";        // Chuyến đi bị hủy
  
  // Thông báo liên quan đến tài xế
  static const String NOTIFICATION_DRIVER_APPROVED = "DRIVER_APPROVED";      // Hồ sơ tài xế được duyệt
  static const String NOTIFICATION_DRIVER_REJECTED = "DRIVER_REJECTED";      // Hồ sơ tài xế bị từ chối
  
  // Thông báo hệ thống
  static const String NOTIFICATION_SYSTEM = "SYSTEM";                        // Thông báo hệ thống
  static const String NOTIFICATION_CHAT_MESSAGE = "CHAT_MESSAGE";            // Tin nhắn chat

  // Các endpoint API
  String get loginEndpoint => '$fullApiUrl/auth/login';
  String get registerEndpoint => '$fullApiUrl/auth/register';
  String get userProfileEndpoint => '$fullApiUrl/user/profile';
  String get notificationsEndpoint => '$fullApiUrl/notifications';
  String get chatEndpoint => '$fullApiUrl/chat';
  String get availableRidesEndpoint => '$fullApiUrl/ride/available';
  String get searchRidesEndpoint => '$fullApiUrl/ride/search';

  // Build endpoint động
  String getEndpoint(String path) => '$fullApiUrl/$path';

  // Các route của WebSocket
  String get notificationTopic => '/topic/notifications';
  String get chatTopic => '/topic/chat';

  // Cập nhật URL gốc
  void updateBaseUrl(String newUrl) {
    if (newUrl.isNotEmpty) {
      // Đảm bảo URL không có dấu / ở cuối
      apiBaseUrl =
          newUrl.endsWith('/')
              ? newUrl.substring(0, newUrl.length - 1)
              : newUrl;

      print('API Base URL đã được cập nhật: $apiBaseUrl');
      print('WebSocket URL: $webSocketUrl');
      print('Full API URL: $fullApiUrl');
    }
  }

  // Trả về URL cơ sở
  String getBaseUrl() {
    return isUsingFallback ? fallbackApiUrl : apiBaseUrl;
  }

  // Check if a URL is working with timeout
  Future<bool> isUrlWorking(String url, {int timeoutSeconds = 5}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = Duration(seconds: timeoutSeconds);
      
      final request = await client.getUrl(Uri.parse(url));
      request.headers.add('Connection', 'close');
      final response = await request.close().timeout(Duration(seconds: timeoutSeconds));
      
      await response.drain<void>();
      client.close();
      return response.statusCode < 400;
    } catch (e) {
      print('Lỗi khi kiểm tra URL $url: $e');
      return false;
    }
  }

  // Kiểm tra xem URL ngrok có đang hoạt động hay không
  Future<bool> isNgrokUrlWorking() async {
    return await isUrlWorking(apiBaseUrl);
  }
  
  // Kiểm tra URL dự phòng có đang hoạt động hay không
  Future<bool> isFallbackUrlWorking() async {
    return await isUrlWorking(fallbackApiUrl);
  }
  
  // Automatically switch to fallback URL if primary is not working
  Future<bool> switchToWorkingUrl() async {
    if (!isUsingFallback) {
      // Check if primary URL is working
      if (await isNgrokUrlWorking()) {
        return true; // Already using working primary URL
      } else {
        // Check if fallback URL is working
        if (await isFallbackUrlWorking()) {
          isUsingFallback = true;
          print('Đã chuyển sang dùng URL dự phòng: $fallbackApiUrl');
          return true;
        } else {
          print('Cả URL chính và URL dự phòng đều không hoạt động!');
          return false;
        }
      }
    } else {
      // Check if primary URL is working again to switch back
      if (await isNgrokUrlWorking()) {
        isUsingFallback = false;
        print('Đã chuyển lại URL chính: $apiBaseUrl');
        return true;
      } else if (await isFallbackUrlWorking()) {
        return true; // Continue using working fallback URL
      } else {
        print('Cả URL chính và URL dự phòng đều không hoạt động!');
        return false;
      }
    }
  }
  
  // Determine if a ride is ongoing (đang diễn ra) based on startTime
  bool isRideOngoing(String rideStatus, DateTime startTime) {
    final now = DateTime.now();
    return rideStatus == RIDE_STATUS_ACTIVE && now.isAfter(startTime);
  }
  
  // Check if a ride is about to start (sắp diễn ra)
  bool isRideUpcoming(String rideStatus, DateTime startTime) {
    final now = DateTime.now();
    return rideStatus == RIDE_STATUS_ACTIVE && now.isBefore(startTime);
  }
  
  // Check if a booking is ongoing
  bool isBookingOngoing(String bookingStatus, DateTime startTime) {
    final now = DateTime.now();
    return bookingStatus == BOOKING_STATUS_ACCEPTED && now.isAfter(startTime);
  }
  
  // Check if a booking is upcoming
  bool isBookingUpcoming(String bookingStatus, DateTime startTime) {
    final now = DateTime.now();
    return bookingStatus == BOOKING_STATUS_ACCEPTED && now.isBefore(startTime);
  }
  
  // Get appropriate ride status text based on status and time
  String getRideStatusText(String rideStatus, DateTime startTime) {
    final now = DateTime.now();
    
    if (rideStatus == RIDE_STATUS_ACTIVE) {
      if (now.isAfter(startTime)) {
        return "Đang diễn ra";
      } else {
        return "Sắp diễn ra";
      }
    } else if (rideStatus == RIDE_STATUS_DRIVER_CONFIRMED) {
      return "Tài xế đã xác nhận";
    } else if (rideStatus == RIDE_STATUS_COMPLETED) {
      return "Đã hoàn thành";
    } else if (rideStatus == RIDE_STATUS_CANCELLED) {
      return "Đã hủy";
    } else {
      return "Không xác định";
    }
  }
  
  // Get booking status text based on booking status and time
  String getBookingStatusText(String bookingStatus, DateTime startTime, String rideStatus) {
    final now = DateTime.now();
    final status = bookingStatus.toUpperCase();
    
    // Nếu chuyến đi đã hoàn thành, hiển thị trạng thái của chuyến đi
    if (rideStatus.toUpperCase() == RIDE_STATUS_COMPLETED) {
      return "Đã hoàn thành";
    }
    
    // Hiển thị theo trạng thái booking
    switch (status) {
      case BOOKING_STATUS_PENDING:
        return "Đang chờ tài xế duyệt";
        
      case BOOKING_STATUS_ACCEPTED:
      case "APPROVED": // Thêm trạng thái APPROVED để xử lý đồng nhất với ACCEPTED
        if (now.isAfter(startTime)) {
          return "Đang đi";
        } else {
          return "Đã được duyệt - sắp diễn ra";
        }
        
      case BOOKING_STATUS_IN_PROGRESS:
        return "Đang diễn ra";
        
      case BOOKING_STATUS_PASSENGER_CONFIRMED:
        return "Đã xác nhận từ khách";
        
      case BOOKING_STATUS_DRIVER_CONFIRMED:
        return "Tài xế đã xác nhận";
        
      case BOOKING_STATUS_COMPLETED:
        return "Đã hoàn thành";
        
      case BOOKING_STATUS_CANCELLED:
        return "Đã hủy";
        
      case BOOKING_STATUS_REJECTED:
        return "Từ chối";
        
      default:
        return "Trạng thái không xác định: $status";
    }
  }
  
  // Ride: Check if should show confirmation button for driver
  bool shouldShowDriverConfirmButton(String rideStatus, DateTime startTime) {
    final now = DateTime.now();
    return rideStatus == RIDE_STATUS_ACTIVE && now.isAfter(startTime);
  }
  
  // Booking: Check if confirmation button should be shown for passenger
  bool shouldShowPassengerConfirmButton(String bookingStatus, DateTime startTime) {
    final now = DateTime.now();
    final status = bookingStatus.toUpperCase();
    
    // Hiển thị nút xác nhận khi trạng thái là ACCEPTED (đã được duyệt) 
    // hoặc APPROVED (đã được duyệt - cũ)
    // hoặc IN_PROGRESS (đang diễn ra) và đã qua thời gian khởi hành
    return (status == BOOKING_STATUS_ACCEPTED || status == "APPROVED" || status == BOOKING_STATUS_IN_PROGRESS) && now.isAfter(startTime);
  }
}
