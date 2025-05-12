import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'views/theme/app_theme.dart';
import 'app_route.dart';
import 'utils/token_tester.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'utils/app_config.dart';
import 'views/screens/chat/user_list_screen.dart';
import 'views/screens/chat/chat_room_screen.dart';
import 'views/screens/common/splash_screen.dart';


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
    await FirebaseMessaging.instance.getToken();
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
      _initializeServices();
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
      print("Error initializing notifications: $e");
      // Continue without notifications if initialization fails
    }
  }

  Future<void> _initializeServices() async {
    // Initialize existing services
    await _initializeNotifications();
    
    // Initialize profile services for both user types
    final profileService = ProfileService();
    final driverProfileService = DriverProfileService();
    
    // Pre-load user profile if logged in
    final authManager = AuthManager();
    final token = await authManager.getToken();
    
    if (token != null) {
      final role = await authManager.getUserRole();
      if (role == 'DRIVER') {
        await driverProfileService.getDriverProfile();
      } else {
        await profileService.getUserProfile();
      }
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
      routes: {
        '/': (context) => const SplashScreen(),
      },
    );
  }
}
