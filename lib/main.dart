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
  // Ensure Firebase is initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  // For testing JWT parsing
  // TokenTester.runTest();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Get FCM token
  await FirebaseMessaging.instance.getToken();
  
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
    final appConfig = AppConfig();
    await NotificationService().initialize(navigatorKey.currentContext, appConfig.apiBaseUrl);
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
