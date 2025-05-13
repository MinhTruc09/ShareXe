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
  } catch (e) { 
    debugPrint("Error handling background message: $e");
  }
}

Future<void> main() async {
  // For testing JWT parsing
  // TokenTester.runTest();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for better performance
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase with error handling
  _initializeFirebase();

  // Run the app
  runApp(const MyApp());
}

// Extract Firebase initialization to a separate method
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );

    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: ${token?.substring(0, 10)}...');
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
      await NotificationService().initialize(
        navigatorKey.currentContext,
        _appConfig.apiBaseUrl,
      );
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
    } catch (e) {
      debugPrint("Error checking API URLs: $e");
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
      builder: (context, child) {
        return MediaQuery(
          // Set text scaling to prevent layout issues
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}
