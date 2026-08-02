import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import 'mock_pet.dart';

/// Card summarizing a single pet on the Home dashboard. Purely
/// presentational — data comes from [MockPet].
class PetSummaryCard extends StatelessWidget {
  const PetSummaryCard({super.key, required this.pet, this.onTap});

  final MockPet pet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(pet.avatarIcon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: AppTypography.h3),
                const SizedBox(height: 2),
                Text(pet.breed, style: AppTypography.bodySecondary),
                const SizedBox(height: 2),
                Text(pet.details, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppBadge(label: pet.statusLabel, color: pet.statusColor),
          const Icon(AppIcons.chevronRight, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
