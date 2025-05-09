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
    bodyLarge: TextStyle(color: Color(0xFF002D62)),
    bodyMedium: TextStyle(color: Color(0xFF002D62)),
    bodySmall: TextStyle(color: Color(0xFF002D62)),
    titleLarge: TextStyle(color: Color(0xFF002D62)),
    titleMedium: TextStyle(color: Color(0xFF002D62)),
    titleSmall: TextStyle(color: Color(0xFF002D62)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF00AEEF),
    foregroundColor: Colors.white,
  ),
);
