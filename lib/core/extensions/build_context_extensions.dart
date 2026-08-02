import 'package:flutter/material.dart';

/// Convenience accessors for common `Theme.of(context)` lookups, keeping
/// widget code terse and free of repeated boilerplate.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  /// Shows a simple snackbar with the given [message].
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colorScheme.error : null,
        ),
      );
  }
}
