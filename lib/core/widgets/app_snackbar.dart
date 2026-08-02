import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent snackbar presentation for success/error/info feedback.
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, backgroundColor: AppColors.success);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, backgroundColor: AppColors.error);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message);
  }

  static void _show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
