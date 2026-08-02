import 'package:flutter/material.dart';

/// Design-system color tokens. All widgets must reference these constants
/// (or the derived [ColorScheme]) rather than hardcoding color values.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color success = Color(0xFF22C55E);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF111827);

  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF6B7280);
}
