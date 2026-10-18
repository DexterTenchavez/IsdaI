import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryDark = Color(0xFF08306B);
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color accent = Color(0xFFFF7043);
  static const Color background = Color.fromARGB(255, 105, 164, 242);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF1B2430);
  static const Color textMuted = Color(0xFF7A8699);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFD32F2F);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.textDark,
      ),
    );
  }
}