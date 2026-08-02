import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular user/pet avatar with an image fallback to initials.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.radius = 24,
  });

  final String? imageUrl;
  final String fallbackText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: hasImage
          ? null
          : Text(
              fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.7,
              ),
            ),
    );
  }
}
