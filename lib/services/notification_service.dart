import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Observable để theo dõi trạng thái booking
  final Rx<Map<String, dynamic>> currentBooking = Rx<Map<String, dynamic>>({});

  Future<void> init() async {
    // Cấu hình local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng tap vào notification
      },
    );

    // Yêu cầu quyền notification
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Lắng nghe FCM message khi app đang mở
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Lắng nghe FCM message khi app ở background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Lấy FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      // Lưu token vào database hoặc gửi lên server
      _saveFcmToken(token);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Hiển thị local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Thông báo mới',
      body: message.notification?.body ?? '',
    );

    // Cập nhật trạng thái booking nếu có
    if (message.data.containsKey('bookingId')) {
      _listenToBookingUpdates(message.data['bookingId']);
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'booking_channel',
      'Booking Notifications',
      channelDescription: 'Notifications for booking updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  void _listenToBookingUpdates(String bookingId) {
    final bookingRef = _database.ref('bookings/$bookingId');
    bookingRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        currentBooking.value = data;
      }
    });
  }

  Future<void> _saveFcmToken(String token) async {
    // Lưu token vào database hoặc gửi lên server
    // Implement theo logic của bạn
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Xử lý message khi app ở background
  print('Handling a background message: ${message.messageId}');
} 