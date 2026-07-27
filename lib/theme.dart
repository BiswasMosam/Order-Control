import 'package:flutter/material.dart';

/// High contrast dark theme. Chosen so status colours read instantly
/// from arm's length in a busy shop.
class AppColors {
  static const bg = Color(0xFF14161A);
  static const surface = Color(0xFF1D2026);
  static const surfaceHi = Color(0xFF272B33);
  static const line = Color(0xFF343943);

  static const text = Color(0xFFF2F4F7);
  static const textDim = Color(0xFF9AA2B1);

  static const cooking = Color(0xFFFF9F43); // not ready yet
  static const ready = Color(0xFF2ED573); // food is ready
  static const paid = Color(0xFF3DA5FF); // money collected
  static const danger = Color(0xFFFF5A5F);
  static const accent = Color(0xFFFFC542);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    dividerColor: AppColors.line,
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
  );
}
