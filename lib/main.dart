import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/theme/app_theme.dart';
import 'app_route.dart';
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
    debugPrint("Handling a background message: ${message.messageId}");
    debugPrint("Message data: ${message.data}");
    debugPrint("Message notification: ${message.notification?.title}");
  } catch (e) {
    debugPrint("Error handling background message: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for better performance
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase with error handling
  await _initializeFirebase();

  // Run the app
  runApp(const MyApp());
}

// Extract Firebase initialization to a separate method
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint("Background message handler set up");

    // Request notification permissions
    final permission = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );
    debugPrint(
      "Notification permission status: ${permission.authorizationStatus}",
    );

    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('FCM Token: ${token.substring(0, 10)}...');
    } else {
      debugPrint("FCM Token not available");
    }
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
    // Continue without Firebase if initialization fails
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final AppConfig _appConfig = AppConfig();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize notification service after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });

    // Pre-check API URL health
    _checkApiUrls();
  }

  // Initialize the notification service with the current context
  Future<void> _initializeNotifications() async {
    try {
      if (navigatorKey.currentContext != null) {
        await NotificationService().initialize(
          navigatorKey.currentContext!,
          _appConfig.apiBaseUrl,
        );
        debugPrint("Notification service initialized successfully");
      } else {
        debugPrint(
          "Navigator context not available for notification initialization",
        );
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing notifications: $e");
      // Continue without notifications if initialization fails
      setState(() {
        _isInitialized = true;
      });
    }
  }

  // Check API URLs health at startup
  Future<void> _checkApiUrls() async {
    try {
      await _appConfig.switchToWorkingUrl();
      debugPrint("API URL health check completed");
    } catch (e) {
      debugPrint("Error checking API URLs: $e");
      // Continue with default URL if health check fails
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Show loading indicator if not initialized yet
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Đang khởi tạo ứng dụng...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: AppRoute.splash,
      onGenerateRoute: AppRoute.onGenerateRoute,
      builder: (context, child) {
        return MediaQuery(
          // Set text scaling to prevent layout issues
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      // Add error handling for route generation
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(title: const Text('Lỗi')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy trang: ${settings.name}',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              AppRoute.splash,
                            ),
                        child: const Text('Về trang chủ'),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }
}
