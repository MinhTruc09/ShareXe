import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/http_client.dart';
import 'auth_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/app_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ApiClient _apiClient;
  final AuthManager _authManager = AuthManager();
  final AppConfig _appConfig = AppConfig();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Thêm WebSocket để nhận thông báo realtime
  WebSocketChannel? _socketChannel;
  StreamSubscription? _socketSubscription;

  // Stream controller để phát thông báo mới đến toàn bộ ứng dụng
  final _notificationController =
      StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get notificationStream =>
      _notificationController.stream;

  // Stream cho từng loại thông báo cụ thể
  final _bookingNotificationController =
      StreamController<NotificationModel>.broadcast();
  final _messageNotificationController =
      StreamController<NotificationModel>.broadcast();
  final _driverNotificationController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get bookingNotificationStream =>
      _bookingNotificationController.stream;
  Stream<NotificationModel> get messageNotificationStream =>
      _messageNotificationController.stream;
  Stream<NotificationModel> get driverNotificationStream =>
      _driverNotificationController.stream;

  NotificationService._internal() : _apiClient = ApiClient();

  // Initialize Firebase Cloud Messaging
  Future<void> initialize(BuildContext? context, String baseUrl) async {
    if (baseUrl.isNotEmpty) {
      _appConfig.updateBaseUrl(baseUrl);
    }

    // Request permission for notifications (iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print(
        'User granted notification permission: ${settings.authorizationStatus}',
      );
    }

    // Listen for FCM token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      if (kDebugMode) {
        print('FCM Token: $fcmToken');
      }
      _updateFcmToken(fcmToken);
    });

    // Hàm xử lý thông báo khi ứng dụng đang chạy
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        // Xử lý hiển thị thông báo
        _handleForegroundMessage(message);

        // Chuyển thông báo thành NotificationModel nếu cần
        if (message.data.containsKey('id')) {
          try {
            final notification = NotificationModel(
              id: int.parse(message.data['id'] ?? '0'),
              userEmail: message.data['userEmail'] ?? '',
              title: message.notification?.title ?? '',
              content: message.notification?.body ?? '',
              type: message.data['type'] ?? '',
              referenceId: int.parse(message.data['referenceId'] ?? '0'),
              read: false,
              createdAt: DateTime.now(),
            );

            // Phát thông báo đến stream
            _broadcastNotification(notification);
          } catch (e) {
            if (kDebugMode) {
              print('Lỗi khi xử lý thông báo FCM: $e');
            }
          }
        }
      }
    });

    // Handle notification clicks when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Handle the notification click, e.g., navigate to a specific screen
      if (message.data['bookingId'] != null) {
        // This would be handled in your app's routing logic
        print('Navigate to booking detail: ${message.data['bookingId']}');
      }
    });

    // Khởi tạo local notifications
    await _setupLocalNotifications();

    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      _updateFcmToken(token);
    }

    // Khởi tạo kết nối WebSocket khi người dùng đã đăng nhập
    final isLoggedIn = await _authManager.isLoggedIn();
    if (isLoggedIn) {
      await _setupWebSocketConnection();
    }

    // Kiểm tra thông báo từ chối tài xế khi khởi động app
    if (context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(
          const Duration(seconds: 2),
        ); // Đợi app khởi động hoàn tất
        await checkDriverRejectionOnStartup(context);
      });
    }
  }

  // Thiết lập kết nối WebSocket
  Future<void> _setupWebSocketConnection() async {
    try {
      // Lấy token JWT từ AuthManager
      final token = await _authManager.getAccessToken();
      if (token == null) return;

      // Lấy baseUrl từ AppConfig và chuyển từ HTTP sang WebSocket
      String baseUrl = _appConfig.getBaseUrl().replaceFirst('http', 'ws');

      // Kết nối đến WebSocket endpoint với token xác thực
      _socketChannel = IOWebSocketChannel.connect(
        Uri.parse('$baseUrl/ws/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Đăng ký lắng nghe tin nhắn từ WebSocket
      _socketSubscription = _socketChannel!.stream.listen(
        (dynamic message) {
          if (kDebugMode) {
            print('Received WebSocket message: $message');
          }

          try {
            final data = json.decode(message as String);
            if (data['type'] == 'NOTIFICATION') {
              final notification = NotificationModel.fromJson(
                data['notification'],
              );

              // Hiển thị thông báo nếu app đang chạy
              showLocalNotification(notification);

              // Phát thông báo đến stream
              _broadcastNotification(notification);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Lỗi khi xử lý WebSocket message: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
          // Thử kết nối lại sau 5 giây
          Future.delayed(const Duration(seconds: 5), () {
            _setupWebSocketConnection();
          });
        },
        onDone: () {
          if (kDebugMode) {
            print('WebSocket connection closed');
          }
          // Thử kết nối lại sau 5 giây
          Future.delayed(const Duration(seconds: 5), () {
            _setupWebSocketConnection();
          });
        },
      );

      if (kDebugMode) {
        print('WebSocket connection established');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi thiết lập WebSocket: $e');
      }
      // Thử kết nối lại sau 5 giây
      Future.delayed(const Duration(seconds: 5), () {
        _setupWebSocketConnection();
      });
    }
  }

  // Đóng kết nối WebSocket
  void closeWebSocketConnection() {
    _socketSubscription?.cancel();
    _socketChannel?.sink.close();
    _socketChannel = null;
  }

  // Phát thông báo đến các stream
  void _broadcastNotification(NotificationModel notification) {
    // Phát thông báo đến tất cả các subscribers
    _notificationController.add(notification);

    // Phát thông báo đến stream theo loại
    switch (notification.type) {
      case 'BOOKING_REQUEST':
      case 'BOOKING_ACCEPTED':
      case 'BOOKING_REJECTED':
      case 'BOOKING_CANCELED':
        _bookingNotificationController.add(notification);
        break;
      case 'CHAT_MESSAGE':
        _messageNotificationController.add(notification);
        break;
      case 'DRIVER_APPROVED':
      case 'DRIVER_REJECTED':
        _driverNotificationController.add(notification);
        break;
    }
  }

  // Dispose streams khi service bị hủy
  void dispose() {
    _socketSubscription?.cancel();
    _socketChannel?.sink.close();
    _notificationController.close();
    _bookingNotificationController.close();
    _messageNotificationController.close();
    _driverNotificationController.close();
  }

  // Thêm một phương thức để xử lý kết nối lại khi login
  Future<void> connectAfterLogin() async {
    await _setupWebSocketConnection();
  }

  // Đăng xuất và đóng kết nối
  Future<void> disconnectOnLogout() async {
    closeWebSocketConnection();
  }

  // Cập nhật FCM token lên server
  Future<void> _updateFcmToken(String token) async {
    try {
      final response = await _apiClient.post(
        '/user/update-fcm-token',
        body: {'token': token},
        requireAuth: true,
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Lỗi khi cập nhật FCM token: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi cập nhật FCM token: $e');
      }
    }
  }

  // Xử lý thông báo khi app đang mở
  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'sharexe_channel_id',
            'ShareXE Notifications',
            channelDescription: 'Thông báo từ ứng dụng ShareXE',
            importance: Importance.max,
            priority: Priority.high,
            icon: android.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // Xử lý khi người dùng nhấn vào thông báo
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        final data = json.decode(payload);
        // Xử lý chuyển hướng dựa trên loại thông báo
        if (data['type'] == 'booking_accepted') {
          // Chuyển hướng đến trang chi tiết booking
          // Ví dụ: navigatorKey.currentState?.pushNamed('/booking-detail', arguments: data['bookingId']);
        } else if (data['type'] == 'chat_message') {
          // Chuyển hướng đến trang chat
        }
      } catch (e) {
        if (kDebugMode) {
          print('Lỗi khi xử lý notification tap: $e');
        }
      }
    }
  }

  // Set up real-time listener for a specific booking
  Stream<Booking?> setupBookingStatusListener(int bookingId) {
    DatabaseReference bookingRef = _database.ref('bookings/$bookingId');

    return bookingRef.onValue.map((event) {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return Booking.fromJson(data);
        } catch (e) {
          print('Error parsing booking data: $e');
          return null;
        }
      }
      return null;
    });
  }

  // Update booking in Firebase Realtime Database when a driver accepts it
  Future<void> updateBookingStatus(int bookingId, String status) async {
    try {
      DatabaseReference bookingRef = _database.ref('bookings/$bookingId');
      await bookingRef.update({'status': status});
      print('Booking status updated in Firebase Realtime Database');
    } catch (e) {
      print('Error updating booking status in Firebase: $e');
    }
  }

  // Chấp nhận booking (cho driver)
  Future<bool> acceptBooking(int bookingId) async {
    try {
      final response = await _apiClient.post(
        '/driver/accept/$bookingId',
        requireAuth: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi chấp nhận booking: $e');
      }
      return false;
    }
  }

  // Từ chối booking (cho driver)
  Future<bool> rejectBooking(int bookingId) async {
    try {
      final response = await _apiClient.post(
        '/driver/reject/$bookingId',
        requireAuth: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi từ chối booking: $e');
      }
      return false;
    }
  }

  // Lấy danh sách tất cả thông báo
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.get(
        '/notifications',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => NotificationModel.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Lỗi khi tải thông báo: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy thông báo: $e');
      }
      return [];
    }
  }

  // Đánh dấu thông báo đã đọc
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _apiClient.put(
        '/notifications/$notificationId/read',
        requireAuth: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi đánh dấu thông báo đã đọc: $e');
      }
      return false;
    }
  }

  // Đánh dấu tất cả thông báo đã đọc
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.put(
        '/notifications/read-all',
        requireAuth: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi đánh dấu tất cả thông báo đã đọc: $e');
      }
      return false;
    }
  }

  // Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get(
        '/notifications/unread-count',
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] ?? 0;
        } else {
          return 0;
        }
      } else {
        throw Exception(
          'Lỗi khi tải số thông báo chưa đọc: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy số thông báo chưa đọc: $e');
      }
      return 0;
    }
  }

  // Hiển thị thông báo cục bộ
  Future<void> showLocalNotification(NotificationModel notification) async {
    try {
      if (kDebugMode) {
        print('Đang hiển thị thông báo: ${notification.title}');
      }

      // Cấu hình chi tiết cho Android
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'sharexe_channel_id',
            'ShareXE Thông báo',
            channelDescription: 'Kênh thông báo ứng dụng ShareXE',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
          );

      // Cấu hình chi tiết cho iOS
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'sharexe_notifications',
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // Đảm bảo notification ID là duy nhất
      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Hiển thị thông báo
      await _flutterLocalNotificationsPlugin.show(
        uniqueId,
        notification.title,
        notification.content,
        platformChannelSpecifics,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId,
        }),
      );

      if (kDebugMode) {
        print('Đã hiển thị thông báo thành công');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo cục bộ: $e');
      }
    }
  }

  // Lấy thông báo từ chối tài xế
  Future<List<NotificationModel>> getDriverRejectionNotifications() async {
    try {
      final allNotifications = await getNotifications();
      // Lọc các thông báo có type là DRIVER_REJECTED
      return allNotifications
          .where((notification) => notification.type == 'DRIVER_REJECTED')
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi lấy thông báo từ chối tài xế: $e');
      }
      return [];
    }
  }

  // Kiểm tra có thông báo từ chối tài xế hay không
  Future<bool> hasDriverRejectionNotifications() async {
    final rejections = await getDriverRejectionNotifications();
    return rejections.isNotEmpty;
  }

  // Xử lý hiển thị thông báo từ chối tài xế
  Future<void> handleDriverRejection(BuildContext context) async {
    try {
      final rejections = await getDriverRejectionNotifications();
      if (rejections.isNotEmpty) {
        // Lấy thông báo từ chối mới nhất
        final latestRejection = rejections.first;

        // Hiển thị thông báo từ chối
        if (!latestRejection.read) {
          // Đánh dấu là đã đọc
          await markAsRead(latestRejection.id);

          // Hiển thị popup
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.gpp_bad, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Hồ sơ tài xế bị từ chối',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          latestRejection.content.split('Lý do:').first.trim(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lý do từ chối:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                extractRejectionReason(
                                      latestRejection.content,
                                    ) ??
                                    'Không có lý do được cung cấp',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Đóng'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Cập nhật hồ sơ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, '/driver/edit-profile');
                      },
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi xử lý thông báo từ chối tài xế: $e');
      }
    }
  }

  // Trích xuất lý do từ chối từ nội dung thông báo
  String? extractRejectionReason(String content) {
    // Trích xuất lý do từ chối từ nội dung thông báo
    // Format: "Nội dung thông báo. Lý do: Lý do từ chối"
    if (content.contains('Lý do:')) {
      return content.split('Lý do:').last.trim();
    }
    return null;
  }

  // Khởi tạo local notifications
  Future<void> _setupLocalNotifications() async {
    try {
      // Cấu hình cho Android
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Cấu hình cho iOS (phiên bản mới không có onDidReceiveLocalNotification)
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            // Hỗ trợ thông báo trên iOS khi app đang chạy
            notificationCategories: [
              DarwinNotificationCategory(
                'chat_message',
                actions: [
                  DarwinNotificationAction.plain(
                    'REPLY',
                    'Trả lời',
                    options: {DarwinNotificationActionOption.foreground},
                  ),
                ],
                options: {DarwinNotificationCategoryOption.allowAnnouncement},
              ),
            ],
          );

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap here
          if (kDebugMode) {
            print('Notification tapped with payload: ${response.payload}');
          }
          _handleNotificationTap(response.payload);
        },
      );

      // Yêu cầu quyền hiển thị thông báo một lần nữa
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      if (kDebugMode) {
        print('Hệ thống thông báo đã được khởi tạo thành công');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi khởi tạo hệ thống thông báo: $e');
      }
    }
  }

  // Kiểm tra thông báo từ chối tài xế khi khởi động app
  Future<void> checkDriverRejectionOnStartup(BuildContext context) async {
    try {
      // Kiểm tra người dùng đã đăng nhập chưa
      final isLoggedIn = await _authManager.isLoggedIn();
      if (isLoggedIn) {
        // Kiểm tra xem người dùng có phải là tài xế không (nếu có API để kiểm tra)
        final rejectionNotifications = await getDriverRejectionNotifications();

        // Lọc các thông báo chưa đọc và mới nhất
        final unreadRejections =
            rejectionNotifications
                .where((notification) => !notification.read)
                .toList();

        if (unreadRejections.isNotEmpty) {
          // Sắp xếp theo thời gian mới nhất
          unreadRejections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          // Lấy thông báo mới nhất để hiển thị
          final latestRejection = unreadRejections.first;

          if (context.mounted) {
            // Đánh dấu thông báo đã đọc
            await markAsRead(latestRejection.id);

            // Hiển thị thông báo popup
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hồ sơ tài xế của bạn chưa được phê duyệt',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          latestRejection.content.split('Lý do:').first.trim(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lý do từ chối:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                extractRejectionReason(
                                      latestRejection.content,
                                    ) ??
                                    'Không có lý do được cung cấp',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.red[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Vui lòng cập nhật lại hồ sơ của bạn để tiếp tục sử dụng tính năng tài xế.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Để sau'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Cập nhật ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, '/driver/edit-profile');
                      },
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi kiểm tra thông báo từ chối tài xế khi khởi động: $e');
      }
    }
  }

  // Hiển thị thông báo cho từng loại thông báo cụ thể
  Future<void> showNotificationByType(NotificationModel notification) async {
    switch (notification.type) {
      case 'BOOKING_REQUEST':
        await showBookingRequestNotification(notification);
        break;
      case 'BOOKING_ACCEPTED':
        await showBookingAcceptedNotification(notification);
        break;
      case 'BOOKING_REJECTED':
        await showBookingRejectedNotification(notification);
        break;
      case 'BOOKING_CANCELED':
        await showBookingCanceledNotification(notification);
        break;
      case 'CHAT_MESSAGE':
        await showChatMessageNotification(notification);
        break;
      case 'DRIVER_APPROVED':
        await showDriverApprovedNotification(notification);
        break;
      case 'DRIVER_REJECTED':
        await showDriverRejectedNotification(notification);
        break;
      default:
        await showLocalNotification(notification);
    }
  }

  // Hiển thị thông báo có người đặt chuyến (cho tài xế)
  Future<void> showBookingRequestNotification(
    NotificationModel notification,
  ) async {
    try {
      // Tạo action buttons cho thông báo (chỉ hỗ trợ trên Android)
      const List<AndroidNotificationAction> actions = [
        AndroidNotificationAction('accept', 'Chấp nhận'),
        AndroidNotificationAction('reject', 'Từ chối'),
      ];

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'booking_request_channel',
            'Yêu cầu đặt chuyến',
            channelDescription: 'Thông báo khi có người đặt chuyến',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            actions: actions,
            color: Color(0xFF002D72),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(categoryIdentifier: 'booking_request'),
      );

      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        uniqueId,
        'Yêu cầu đặt chuyến mới',
        notification.content,
        notificationDetails,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo đặt chuyến: $e');
      }
    }
  }

  // Hiển thị thông báo cho hành khách khi tài xế chấp nhận
  Future<void> showBookingAcceptedNotification(
    NotificationModel notification,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'booking_accepted_channel',
            'Chuyến đi được chấp nhận',
            channelDescription: 'Thông báo khi tài xế chấp nhận chuyến đi',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            color: Color(0xFF4CAF50),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'booking_status',
        ),
      );

      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        uniqueId,
        '✅ Chuyến đi đã được chấp nhận',
        notification.content,
        notificationDetails,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo chấp nhận chuyến: $e');
      }
    }
  }

  // Hiển thị thông báo khi chuyến đi bị từ chối
  Future<void> showBookingRejectedNotification(
    NotificationModel notification,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'booking_rejected_channel',
            'Chuyến đi bị từ chối',
            channelDescription: 'Thông báo khi tài xế từ chối chuyến đi',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            color: Color(0xFFF44336),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(categoryIdentifier: 'booking_status'),
      );

      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        uniqueId,
        '❌ Chuyến đi bị từ chối',
        notification.content,
        notificationDetails,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo từ chối chuyến: $e');
      }
    }
  }

  // Hiển thị thông báo khi hành khách hủy chuyến đi
  Future<void> showBookingCanceledNotification(
    NotificationModel notification,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'booking_canceled_channel',
            'Chuyến đi bị hủy',
            channelDescription: 'Thông báo khi hành khách hủy chuyến đi',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            color: Color(0xFFFF9800),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(categoryIdentifier: 'booking_status'),
      );

      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        uniqueId,
        '🚫 Chuyến đi đã bị hủy',
        notification.content,
        notificationDetails,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo hủy chuyến: $e');
      }
    }
  }

  // Hiển thị thông báo tin nhắn mới
  Future<void> showChatMessageNotification(
    NotificationModel notification,
  ) async {
    try {
      // Thêm action trả lời nhanh (chỉ hỗ trợ trên Android)
      const List<AndroidNotificationAction> actions = [
        AndroidNotificationAction('reply', 'Trả lời'),
      ];

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'chat_message_channel',
            'Tin nhắn mới',
            channelDescription: 'Thông báo khi có tin nhắn mới',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            actions: actions,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(categoryIdentifier: 'chat_message'),
      );

      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        uniqueId,
        notification.title,
        notification.content,
        notificationDetails,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo tin nhắn mới: $e');
      }
    }
  }

  // Hiển thị thông báo khi hồ sơ tài xế được chấp nhận
  Future<void> showDriverApprovedNotification(
    NotificationModel notification,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'driver_approved_channel',
            'Hồ sơ tài xế được chấp nhận',
            channelDescription: 'Thông báo khi hồ sơ tài xế được chấp nhận',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            color: Color(0xFF4CAF50),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(categoryIdentifier: 'driver_status'),
      );

      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _flutterLocalNotificationsPlugin.show(
        uniqueId,
        '✅ Hồ sơ tài xế được chấp nhận',
        'Chúc mừng! Bạn đã có thể bắt đầu nhận các chuyến đi với tư cách tài xế.',
        notificationDetails,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo chấp nhận hồ sơ tài xế: $e');
      }
    }
  }

  // Hiển thị thông báo khi hồ sơ tài xế bị từ chối
  Future<void> showDriverRejectedNotification(
    NotificationModel notification,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'driver_rejected_channel',
            'Hồ sơ tài xế bị từ chối',
            channelDescription: 'Thông báo khi hồ sơ tài xế bị từ chối',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            color: Color(0xFFF44336),
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(categoryIdentifier: 'driver_status'),
      );

      final uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      String rejectionReason =
          extractRejectionReason(notification.content) ??
          'Không có lý do được cung cấp';

      await _flutterLocalNotificationsPlugin.show(
        uniqueId,
        '❌ Hồ sơ tài xế bị từ chối',
        'Hồ sơ tài xế của bạn chưa được phê duyệt. Lý do: $rejectionReason',
        notificationDetails,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId,
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo từ chối hồ sơ tài xế: $e');
      }
    }
  }

  // Add this method to the NotificationService class
  Future<bool> sendNotification(
    String title,
    String message,
    String type,
    Map<String, dynamic> data
  ) async {
    try {
      if (kDebugMode) {
        print('Sending notification: $title, $message, $type');
      }
      
      // Option 1: Use API to send notification
      final token = await _authManager.getToken();
      if (token == null) return false;
      
      // Check the ApiClient implementation to use the correct parameters
      final response = await _apiClient.post(
        '/api/notifications/send',
        body: {
          'title': title,
          'message': message,
          'type': type,
          'data': data,
        },
        requireAuth: true,
      );
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Notification sent successfully via API');
        }
        return true;
      }
      
      // If API failed, try local notification
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userEmail: 'system',
        title: title,
        content: message,
        type: type,
        referenceId: data['rideId'] ?? 0,
        read: false,
        createdAt: DateTime.now(),
      );
      
      // Show local notification
      await showLocalNotification(notification);
      
      // Broadcast to streams
      _broadcastNotification(notification);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending notification: $e');
      }
      return false;
    }
  }
}
