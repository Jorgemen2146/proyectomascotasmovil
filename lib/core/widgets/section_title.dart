import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// Section header used above lists/groups of content (e.g. "Mis Mascotas"),
/// with an optional trailing action such as an add button or "Ver todo".
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.h2),
        ?trailing,
      ],
    );
  }
}
