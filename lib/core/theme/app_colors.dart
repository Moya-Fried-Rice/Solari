import 'package:flutter/material.dart';

/// App-wide color constants
class AppColors {
  // Light theme colors
  static const Color lightPrimary = Color(0xFFA54607);
  static const Color lightText = Colors.black;
  static const Color lightBackground = Colors.white;
  static const Color lightButtonText = Colors.white;
  static const Color lightUnselectedColor = Color(0xFFBDBDBD); // Grey400
  
  // Dark theme colors
  static const Color darkPrimary = Color(0xFFF57600);
  static const Color darkText = Colors.white;
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkButtonText = Colors.black;
  static const Color darkUnselectedColor = Color.fromARGB(255, 172, 86, 5); // Brown600
}
