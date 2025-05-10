import 'dart:convert';
import 'package:http/http.dart' as http;

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // API Base URL - URL ngrok đang hoạt động
  // Lưu ý: URL ngrok thường chỉ hoạt động trong thời gian ngắn (khoảng 2 giờ cho phiên bản miễn phí)
  // Cần cập nhật URL này khi URL ngrok cũ hết hạn
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

  // Get the base URL
  String getBaseUrl() {
    return apiBaseUrl;
  }

  // FCM server key
  String fcmServerKey = 'f84dnNFrSI68W3fy2FHeiH:APA91bHX1mXlG0xMshd59YCqQ5OIXKd__3kbAeKqR0y_UGw5saAfQZ3OvzILUziHHguNI9Ntsdzg-8uT5U0BAzXH_VPMurCIUrcLB-5zJwrAFcn9xEBGAEI';

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

  // Kiểm tra xem URL ngrok có còn hoạt động không
  Future<bool> isNgrokUrlWorking() async {
    try {
      print('Đang kiểm tra URL ngrok: $apiBaseUrl');
      final response = await http
          .get(Uri.parse('$apiBaseUrl/api/health'))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Kết nối quá hạn');
            },
          );

      print('Kết quả kiểm tra URL ngrok: ${response.statusCode}');
      // Nếu nhận được bất kỳ phản hồi nào (ngay cả 404) từ server, URL vẫn hoạt động
      return response.statusCode != 502 && response.statusCode != 504;
    } catch (e) {
      print('Lỗi khi kiểm tra URL ngrok: $e');
      return false;
    }
  }

  // Cập nhật URL khi cần thiết
  Future<bool> checkAndUpdateNgrokUrl(String newUrl) async {
    if (await isNgrokUrlWorking()) {
      print('URL ngrok hiện tại còn hoạt động: $apiBaseUrl');
      return true;
    }

    // URL ngrok hiện tại không hoạt động
    if (newUrl.isNotEmpty) {
      updateBaseUrl(newUrl);
      return await isNgrokUrlWorking();
    }

    return false;
  }
}
