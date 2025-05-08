class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // API Base URL - URL ngrok đang hoạt động
  String apiBaseUrl = 'https://0479-1-54-152-77.ngrok-free.app';

  // API Base Path - Đường dẫn API cơ sở
  String apiBasePath = '/api';

  // Full API URL (apiBaseUrl + apiBasePath)
  String get fullApiUrl => '$apiBaseUrl$apiBasePath';

  // WebSocket URL
  String get webSocketUrl {
    // Chuyển đổi https:// thành wss://
    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://') + '/ws';
    } else if (apiBaseUrl.startsWith('http://')) {
      return apiBaseUrl.replaceFirst('http://', 'ws://') + '/ws';
    } else {
      return apiBaseUrl + '/ws';
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
}
