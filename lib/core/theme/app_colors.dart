import 'package:flutter/material.dart';

/// Yes Shop / Tekeraheza design tokens (from tekeraheza-frontend index.css)
class AppColors {
  static const Color primary = Color(0xFFE31E24);
  static const Color primaryDark = Color(0xFFC41E3A);
  static const Color primaryForeground = Colors.white;

  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF3F4F6);
  static const Color foreground = Color(0xFF1F2937);

  static const Color border = Color(0xFFE5E7EB);
  static const Color mutedForeground = Color(0xFF6B7280);

  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFDBEAFE);
  static const Color destructive = Color(0xFFDC2626);
  static const Color destructiveBg = Color(0xFFFEE2E2);
  static const Color purple = Color(0xFF4F46E5);
  static const Color purpleBg = Color(0xFFE0E7FF);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  // Dark mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkForeground = Color(0xFFF8FAFC);
}
