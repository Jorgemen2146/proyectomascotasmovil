import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../pets/domain/entities/pet.dart';

/// Card summarizing a pet returned by the Pets API.
class PetSummaryCard extends StatelessWidget {
  const PetSummaryCard({super.key, required this.pet, this.onTap});

  final PetSummary pet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppNetworkImage(
            url: pet.mainPhotoUrl,
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: AppTypography.h3),
                const SizedBox(height: 2),
                Text(pet.breedName, style: AppTypography.bodySecondary),
                const SizedBox(height: 2),
                Text(_details, style: AppTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(AppIcons.chevronRight, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  String get _details {
    final age = pet.ageYears;
    final sex = pet.sex.toUpperCase() == 'M' ? 'Macho' : 'Hembra';
    return [
      if (age != null) '$age ${age == 1 ? 'año' : 'años'}',
      sex,
    ].join(' · ');
  }
}
