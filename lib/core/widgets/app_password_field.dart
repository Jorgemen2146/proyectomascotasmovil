import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_text_field.dart';

/// Password input preset over [AppTextField] with a built-in show/hide
/// toggle so every password field in the app behaves identically.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    this.label = 'Contraseña',
    this.validator,
    this.textInputAction,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      obscureText: _obscured,
      prefixIcon: AppIcons.lock,
      textInputAction: widget.textInputAction ?? TextInputAction.next,
      autofillHints: widget.autofillHints ?? const [AutofillHints.password],
      validator: widget.validator ??
          (value) => (value == null || value.length < 6)
              ? 'Mínimo 6 caracteres'
              : null,
      suffixIcon: IconButton(
        icon: Icon(_obscured ? AppIcons.eyeOff : AppIcons.eyeOn),
        onPressed: () => setState(() => _obscured = !_obscured),
      ),
    );
  }
}
