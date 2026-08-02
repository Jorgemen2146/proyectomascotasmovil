import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// Decorative social sign-in row shown for visual parity with the design
/// system. Not wired to real auth providers — taps only surface a
/// "coming soon" message.
class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIconButton(
          icon: Icons.g_mobiledata_rounded,
          iconSize: 28,
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(width: AppSpacing.md),
        _SocialIconButton(
          icon: Icons.apple_rounded,
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(width: AppSpacing.md),
        _SocialIconButton(
          icon: Icons.facebook_rounded,
          color: AppColors.primary,
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    AppSnackBar.showInfo(context, 'Próximamente disponible.');
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.textPrimary,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
