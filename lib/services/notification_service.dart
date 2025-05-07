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

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final ApiClient _apiClient;
  final AuthManager _authManager = AuthManager();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  String _baseUrl = 'https://yourapi.com'; // Thay thế bằng URL thực tế
  
  NotificationService._internal() 
    : _apiClient = ApiClient(baseUrl: 'https://e888-2402-800-6318-7ea8-e9f3-483b-bf46-df23.ngrok-free.app/api');
  
  // Initialize Firebase Cloud Messaging
  Future<void> initialize(BuildContext? context, String baseUrl) async {
    _baseUrl = baseUrl;
    
    // Request permission for notifications (iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (kDebugMode) {
      print('User granted notification permission: ${settings.authorizationStatus}');
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
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
    
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
    
    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      _updateFcmToken(token);
    }
  }
  
  // Cập nhật FCM token lên server
  Future<void> _updateFcmToken(String token) async {
    try {
      final authToken = await _authManager.getToken();
      if (authToken == null) return;
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/user/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'token': token}),
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
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/driver/accept/$bookingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      final token = await _authManager.getToken();
      if (token == null) {
        throw Exception('Không tìm thấy token xác thực');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'] ?? 0;
        } else {
          return 0;
        }
      } else {
        throw Exception('Lỗi khi tải số thông báo chưa đọc: ${response.statusCode}');
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
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'sharexe_channel_id',
        'ShareXE Thông báo',
        channelDescription: 'Kênh thông báo ứng dụng ShareXE',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();
      
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        notification.id,
        notification.title,
        notification.content,
        platformChannelSpecifics,
        payload: json.encode({
          'type': notification.type,
          'referenceId': notification.referenceId
        }),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi hiển thị thông báo cục bộ: $e');
      }
    }
  }
} 