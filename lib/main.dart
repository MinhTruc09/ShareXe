import 'package:flutter/material.dart';
import 'views/theme/app_theme.dart';
import 'app_route.dart';
import 'utils/token_tester.dart';

void main() {
  // For testing JWT parsing
  // TokenTester.runTest();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: AppRoute.splash,
      onGenerateRoute: AppRoute.onGenerateRoute,
    );
  }
}
