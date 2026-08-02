import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_text_field.dart';

/// Email input preset over [AppTextField]: keyboard type, icon and
/// autofill hints are wired so screens don't repeat this boilerplate.
class AppEmailField extends StatelessWidget {
  const AppEmailField({
    super.key,
    required this.controller,
    this.label = 'Correo electrónico',
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: AppIcons.email,
      textInputAction: textInputAction ?? TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      validator: validator ??
          (value) => (value == null || !value.contains('@'))
              ? 'Ingresa un correo válido'
              : null,
    );
  }
}
