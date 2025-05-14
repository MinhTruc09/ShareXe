import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;

  // Private constructor
  AppConfig._internal();

  // API URLs with automatic backup URLs
  String apiBaseUrl = 'https://2675-115-76-90-173.ngrok-free.app';
  String fallbackApiUrl = 'https://sharexe-api.onrender.com';

  // Flag to indicate if using fallback URL
  bool isUsingFallback = false;

  // URL checking cache data
  DateTime _lastUrlCheckTime = DateTime(1970);
  bool _lastPrimaryUrlStatus = false;
  bool _lastFallbackUrlStatus = false;

  // Cache duration
  final Duration _urlCheckCacheDuration = const Duration(minutes: 5);

  // API Base Path
  String apiBasePath = '/api';

  // Full API URL - Computed property with fallback logic
  String get fullApiUrl =>
      '${isUsingFallback ? fallbackApiUrl : apiBaseUrl}$apiBasePath';

  // WebSocket URL with improved computation
  String get webSocketUrl {
    // Base URL selection
    String baseUrl = isUsingFallback ? fallbackApiUrl : apiBaseUrl;

    // Clean up URL - remove trailing slash
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    // Protocol conversion
    String wsUrl;
    if (baseUrl.startsWith('https://')) {
      wsUrl = baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      wsUrl = baseUrl.replaceFirst('http://', 'ws://');
    } else {
      // If no protocol specified, default to secure WebSocket
      wsUrl = 'wss://$baseUrl';
    }

    // Endpoint selection based on URL
    return baseUrl.contains('ngrok')
        ? '$wsUrl/ws/websocket' // Ngrok specific endpoint
        : '$wsUrl/ws'; // Standard endpoint
  }

  // Computed property getters for API endpoints
  String get loginEndpoint => '$fullApiUrl/auth/login';
  String get registerEndpoint => '$fullApiUrl/auth/register';
  String get userProfileEndpoint => '$fullApiUrl/user/profile';
  String get notificationsEndpoint => '$fullApiUrl/notifications';
  String get chatEndpoint => '$fullApiUrl/chat';
  String get availableRidesEndpoint => '$fullApiUrl/ride/available';
  String get searchRidesEndpoint => '$fullApiUrl/ride/search';

  // Notification constants - stored as static to avoid duplication
  // FCM topics
  String fcmTopicAllUsers = 'all_users';
  String fcmTopicDrivers = 'drivers';
  String fcmTopicPassengers = 'passengers';

  // Notification settings
  int notificationAutoDeleteDays = 30; // Thông báo tự động xóa sau 30 ngày

  // Chat settings
  int chatHistoryLimit = 50; // Số lượng tin nhắn tải mỗi lần

  // Time buffer in minutes to determine if a ride is about to start
  int rideStartTimeBuffer = 5; // 5 minutes buffer

  // Ride status constants - Standardized
  static const String RIDE_STATUS_ACTIVE = "ACTIVE";
  static const String RIDE_STATUS_DRIVER_CONFIRMED = "DRIVER_CONFIRMED";
  static const String RIDE_STATUS_COMPLETED = "COMPLETED";
  static const String RIDE_STATUS_CANCELLED = "CANCELLED";

  // Booking status constants - Standardized
  static const String BOOKING_STATUS_PENDING = "PENDING";
  static const String BOOKING_STATUS_ACCEPTED = "ACCEPTED";
  static const String BOOKING_STATUS_IN_PROGRESS = "IN_PROGRESS";
  static const String BOOKING_STATUS_PASSENGER_CONFIRMED =
      "PASSENGER_CONFIRMED";
  static const String BOOKING_STATUS_DRIVER_CONFIRMED = "DRIVER_CONFIRMED";
  static const String BOOKING_STATUS_COMPLETED = "COMPLETED";
  static const String BOOKING_STATUS_CANCELLED = "CANCELLED";
  static const String BOOKING_STATUS_REJECTED = "REJECTED";

  // Notification types - Standardized
  static const String NOTIFICATION_BOOKING_REQUEST = "BOOKING_REQUEST";
  static const String NOTIFICATION_BOOKING_ACCEPTED = "BOOKING_ACCEPTED";
  static const String NOTIFICATION_BOOKING_REJECTED = "BOOKING_REJECTED";
  static const String NOTIFICATION_BOOKING_CANCELLED = "BOOKING_CANCELLED";

  // Ride notifications
  static const String NOTIFICATION_RIDE_CREATED = "RIDE_CREATED";
  static const String NOTIFICATION_RIDE_STARTED = "RIDE_STARTED";
  static const String NOTIFICATION_DRIVER_CONFIRMED = "DRIVER_CONFIRMED";
  static const String NOTIFICATION_PASSENGER_CONFIRMED = "PASSENGER_CONFIRMED";
  static const String NOTIFICATION_RIDE_COMPLETED = "RIDE_COMPLETED";
  static const String NOTIFICATION_RIDE_CANCELLED = "RIDE_CANCELLED";

  // Driver notifications
  static const String NOTIFICATION_DRIVER_APPROVED = "DRIVER_APPROVED";
  static const String NOTIFICATION_DRIVER_REJECTED = "DRIVER_REJECTED";

  // System notifications
  static const String NOTIFICATION_SYSTEM = "SYSTEM";
  static const String NOTIFICATION_CHAT_MESSAGE = "CHAT_MESSAGE";

  // Build dynamic endpoint
  String getEndpoint(String path) {
    // Normalize path to prevent double slashes
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return '$fullApiUrl/$path';
  }

  // WebSocket route constants
  String get notificationTopic => '/topic/notifications';
  String get chatTopic => '/topic/chat';

  // Update URL with proper error checking
  void updateBaseUrl(String newUrl) {
    if (newUrl.isEmpty) return;

    // Clean URL format
    if (newUrl.endsWith('/')) {
      newUrl = newUrl.substring(0, newUrl.length - 1);
    }

    // Add https:// if protocol is missing
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      newUrl = 'https://$newUrl';
    }

    apiBaseUrl = newUrl;

    // Reset URL check cache
    _lastUrlCheckTime = DateTime(1970);
  }

  // Return the current base URL
  String getBaseUrl() {
    return isUsingFallback ? fallbackApiUrl : apiBaseUrl;
  }

  // Check if a URL is working with optimized caching and timeout
  Future<bool> isUrlWorking(String url, {int timeoutSeconds = 5}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = Duration(seconds: timeoutSeconds);

      final request = await client.getUrl(Uri.parse(url));
      request.headers.add('Connection', 'close');

      final response = await request.close().timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          throw TimeoutException(
            'URL check timed out after $timeoutSeconds seconds',
          );
        },
      );

      await response.drain<void>();
      client.close();
      return response.statusCode < 400;
    } catch (e) {
      debugPrint('URL check error for $url: $e');
      return false;
    }
  }

  // Check primary URL with caching
  Future<bool> isNgrokUrlWorking() async {
    final now = DateTime.now();
    // Return cached result if recent
    if (now.difference(_lastUrlCheckTime) < _urlCheckCacheDuration) {
      return _lastPrimaryUrlStatus;
    }

    // Check URL
    final result = await isUrlWorking(apiBaseUrl);

    // Update cache
    _lastPrimaryUrlStatus = result;
    _lastUrlCheckTime = now;

    return result;
  }

  // Check fallback URL with caching
  Future<bool> isFallbackUrlWorking() async {
    final now = DateTime.now();
    // Return cached result if recent
    if (now.difference(_lastUrlCheckTime) < _urlCheckCacheDuration) {
      return _lastFallbackUrlStatus;
    }

    // Check URL
    final result = await isUrlWorking(fallbackApiUrl);

    // Update cache
    _lastFallbackUrlStatus = result;
    _lastUrlCheckTime = now;

    return result;
  }

  // Smartly switch to the working URL
  Future<bool> switchToWorkingUrl() async {
    final now = DateTime.now();
    final needToCheckUrls =
        now.difference(_lastUrlCheckTime) >= _urlCheckCacheDuration;

    // If currently using primary URL
    if (!isUsingFallback) {
      // Check if we need to verify the URL again
      if (needToCheckUrls) {
        _lastPrimaryUrlStatus = await isUrlWorking(apiBaseUrl);
        _lastUrlCheckTime = now;

        // Stay on primary URL if it's working
        if (_lastPrimaryUrlStatus) {
          return true;
        }

        // Check fallback URL
        _lastFallbackUrlStatus = await isUrlWorking(fallbackApiUrl);

        // Switch to fallback if it's working
        if (_lastFallbackUrlStatus) {
          isUsingFallback = true;
          debugPrint('Switched to fallback URL: $fallbackApiUrl');
          return true;
        }

        debugPrint('Both primary and fallback URLs are unavailable!');
        return false;
      } else {
        // Use cached status if we checked recently
        if (!_lastPrimaryUrlStatus && _lastFallbackUrlStatus) {
          isUsingFallback = true;
          debugPrint(
            'Switched to fallback URL: $fallbackApiUrl (cached status)',
          );
        }
        return _lastPrimaryUrlStatus || _lastFallbackUrlStatus;
      }
    }
    // Currently using fallback
    else {
      // Periodically check if primary URL is back online
      if (needToCheckUrls) {
        _lastPrimaryUrlStatus = await isUrlWorking(apiBaseUrl);
        _lastUrlCheckTime = now;

        // If primary URL is now working again, switch back
        if (_lastPrimaryUrlStatus) {
          isUsingFallback = false;
          debugPrint('Switched back to primary URL: $apiBaseUrl');
          return true;
        }

        // Check if fallback is still working
        _lastFallbackUrlStatus = await isUrlWorking(fallbackApiUrl);
        return _lastFallbackUrlStatus;
      }

      return _lastFallbackUrlStatus;
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
  String getBookingStatusText(
    String bookingStatus,
    DateTime startTime,
    String rideStatus,
  ) {
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
        return "Đang đi";

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
  bool shouldShowPassengerConfirmButton(
    String bookingStatus,
    DateTime startTime,
  ) {
    final now = DateTime.now();
    final status = bookingStatus.toUpperCase();

    // Hiển thị nút xác nhận khi trạng thái là ACCEPTED (đã được duyệt)
    // hoặc APPROVED (đã được duyệt - cũ)
    // hoặc IN_PROGRESS (đang diễn ra) và đã qua thời gian khởi hành
    return (status == BOOKING_STATUS_ACCEPTED ||
            status == "APPROVED" ||
            status == BOOKING_STATUS_IN_PROGRESS) &&
        now.isAfter(startTime);
  }
}
