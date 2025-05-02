import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  fontFamily: 'Roboto',
  primaryColor: const Color(0xFF00AEEF),
  scaffoldBackgroundColor: const Color(0xFF00AEEF),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: const Color(0xFF00AEEF),
    secondary: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white),
    titleSmall: TextStyle(color: Colors.white),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF00AEEF),
    foregroundColor: Colors.white,
  ),
); 