import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'views/theme/app_theme.dart';
import 'app_route.dart';
import 'utils/token_tester.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'utils/app_config.dart';

// Required for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Ensure Firebase is initialized
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Handling a background message: ${message.messageId}");
  } catch (e) {
    print("Error handling background message: $e");
  }
}

Future<void> main() async {
  // For testing JWT parsing
  // TokenTester.runTest();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Continue without Firebase if initialization fails
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize notification service after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  // Initialize the notification service with the current context
  Future<void> _initializeNotifications() async {
    try {
      final appConfig = AppConfig();
      await NotificationService().initialize(
        navigatorKey.currentContext,
        appConfig.apiBaseUrl,
      );
    } catch (e) {
      // Xử lý lỗi bằng cách ghi nhật ký và tiếp tục - không hiển thị lỗi cho người dùng
      print("Error initializing notifications: $e");
      print("App will continue without notification features");
      // Không hiển thị lỗi này cho người dùng vì nó không ảnh hưởng đến chức năng chính
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: AppRoute.splash,
      onGenerateRoute: AppRoute.onGenerateRoute,
    );
  }
}
