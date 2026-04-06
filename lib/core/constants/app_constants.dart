import 'package:flutter/material.dart';

class AppColors {
  static const background  = Color(0xFF0F1117);
  static const surface     = Color(0xFF111827);
  static const border      = Color(0xFF1E2435);
  static const accent      = Color(0xFF4B7CF3);
  static const textPrimary = Color(0xFFE5E7EB);
  static const textSecond  = Color(0xFF9CA3AF);
  static const success     = Color(0xFF22C55E);
  static const warning     = Color(0xFFEAB308);
  static const error       = Color(0xFFEF4444);
}

class AppStrings {
  static const appName = 'Velona AI';
}

class AppConfig {
  /// 어드민 이메일 목록 (comma-separated 또는 하드코딩)
  static const adminEmails = ['kimeach94@gmail.com'];

  static bool isAdmin(String email) => adminEmails.contains(email);
}
