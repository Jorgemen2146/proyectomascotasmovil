import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/pet.dart';

class PetAttributeChips extends StatelessWidget {
  const PetAttributeChips({super.key, required this.pet});

  final PetSummary pet;

  @override
  Widget build(BuildContext context) {
    final isMale = pet.sex.toUpperCase() == 'M';
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        _PetChip(
          label: isMale ? '♂ Macho' : '♀ Hembra',
          background: isMale ? AppColors.maleSoft : AppColors.femaleSoft,
          foreground: isMale ? AppColors.maleText : AppColors.femaleText,
        ),
        if (pet.ageYears case final age?)
          _PetChip(
            label: '$age ${age == 1 ? 'año' : 'años'}',
            background: AppColors.ageSoft,
            foreground: AppColors.maleText,
          ),
      ],
    );
  }
}

class PetDesignCard extends StatelessWidget {
  const PetDesignCard({
    super.key,
    required this.pet,
    required this.onTap,
    this.compact = false,
  });

  final PetSummary pet;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageSize = compact ? 66.0 : 88.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.border.withValues(alpha: .75)),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardAll,
          child: Padding(
            padding: EdgeInsets.all(
              compact ? AppSpacing.sm : AppSpacing.compact,
            ),
            child: Row(
              children: [
                AppNetworkImage(
                  url: pet.mainPhotoUrl,
                  width: imageSize,
                  height: imageSize,
                  borderRadius: AppRadius.mdAll,
                ),
                const SizedBox(width: AppSpacing.compact),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pet.breedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PetAttributeChips(pet: pet),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  AppIcons.chevronRight,
                  size: 22,
                  color: AppColors.navigationInactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetChip extends StatelessWidget {
  const _PetChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: AppTypography.small.copyWith(color: foreground, fontSize: 10),
        ),
      ),
    );
  }
}
