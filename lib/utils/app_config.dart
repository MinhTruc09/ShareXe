class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();
  
  // API Base URL
  String apiBaseUrl = 'https://209b-2405-4803-c83c-6d40-8464-c5f5-c484-d512.ngrok-free.app';
  
  // WebSocket URL
  String get webSocketUrl => '$apiBaseUrl/ws';
  
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
  String get loginEndpoint => '$apiBaseUrl/api/auth/login';
  String get registerEndpoint => '$apiBaseUrl/api/auth/register';
  String get userProfileEndpoint => '$apiBaseUrl/api/user/profile';
  String get notificationsEndpoint => '$apiBaseUrl/api/notifications';
  String get chatEndpoint => '$apiBaseUrl/api/chat';
  
  // Các route của WebSocket
  String get notificationTopic => '/topic/notifications';
  String get chatTopic => '/topic/chat';
  
  void updateBaseUrl(String newUrl) {
    apiBaseUrl = newUrl;
  }
} 