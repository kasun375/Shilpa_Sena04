import 'package:flutter/material.dart';

class DesignConstants {
  // Brand Colors
  static const Color primaryDark = Color(0xFF001B3D);
  static const Color primaryBlue = Color(0xFF0083D2);
  static const Color primaryCyan = Color(0xFF00D2FF);
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF002952);
  static const Color scaffoldBackground = Color(0xFF00BBF9); // The bright blue in the middle
  
  // Card & Element Colors
  static const Color cardBackground = Color(0xFF041C2B);
  static const Color notificationRed = Color(0xFFFF3B30);
  static const Color accentYellow = Color(0xFFFFB800);
  
  // Gradients
  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF001B3D),
      Color(0xFF004E8C),
      Color(0xFF00BBF9),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF041C2B),
      Color(0xFF082D44),
    ],
  );

  // Text Styles (Base)
  static const double titleFontSize = 24.0;
  static const double bodyFontSize = 16.0;
  
  // Padding & Radius
  static const double horizontalPadding = 20.0;
  static const double borderRadius = 20.0;
}
