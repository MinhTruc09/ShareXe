import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'views/theme/app_theme.dart';
import 'app_route.dart';
import 'utils/token_tester.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // For testing JWT parsing
  // TokenTester.runTest();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Khởi tạo NotificationService
  final notificationService = Get.put(NotificationService());
  await notificationService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: AppRoute.splash,
      onGenerateRoute: AppRoute.onGenerateRoute,
    );
  }
}
