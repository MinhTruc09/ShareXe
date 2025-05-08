import 'dart:convert';
import 'dart:io';
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

  NotificationService._internal() : _apiClient = ApiClient();

  // Initialize Firebase Cloud Messaging
  Future<void> initialize(BuildContext? context, String baseUrl) async {
    try {
      if (baseUrl.isNotEmpty) {
        _appConfig.updateBaseUrl(baseUrl);
      }

      // Request permission for notifications (iOS)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      if (kDebugMode) {
        print(
          'User granted notification permission: ${settings.authorizationStatus}',
        );
      }

      // Xử lý lỗi APNS token trên iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (kDebugMode) {
            print('APNS Token: $apnsToken');
          }

          // Nếu APNS token là null, đợi và thử lại sau
          if (apnsToken == null) {
            if (kDebugMode) {
              print(
                'APNS token is null, will try to initialize FCM without it',
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting APNS token: $e');
            print('Will continue without APNS token');
          }
        }
      }

      // Listen for FCM token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
        if (kDebugMode) {
          print('FCM Token refreshed: $fcmToken');
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

      // Get FCM token with error handling
      try {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          if (kDebugMode) {
            print('FCM Token: $token');
          }
          _updateFcmToken(token);
        } else {
          if (kDebugMode) {
            print(
              'FCM Token is null, notification features may not work correctly',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting FCM token: $e');
          print('App will continue without remote notifications');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notification service: $e');
        print('App will continue without notification features');
      }
    }
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
        '/driver/booking/$bookingId/accept',
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
}
