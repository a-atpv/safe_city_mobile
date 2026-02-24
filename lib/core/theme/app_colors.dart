import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFE55A25);
  static const Color primaryLight = Color(0xFFFF8C42);
  
  // Background
  static const Color background = Color(0xFF0A1628);
  static const Color backgroundLight = Color(0xFF1A2D4A);
  static const Color backgroundCard = Color(0xFF1E3A5F);
  
  // Surface (glassmorphism)
  static const Color surface = Color(0x33FFFFFF);
  static const Color surfaceBorder = Color(0x44FFFFFF);
  
  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B8C4);
  static const Color textHint = Color(0xFF6B7280);
  
  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Emergency
  static const Color sosRed = Color(0xFFDC2626);
  static const Color sosRedGlow = Color(0x66DC2626);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
