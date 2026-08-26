import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/providers.dart';
import '../../domain/entities/pet.dart';

class PetDetailPage extends ConsumerWidget {
  const PetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(petDetailsProvider(petId));
    return detail.when(
      loading: () => const Scaffold(body: AppLoadingIndicator()),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(petDetailsProvider(petId)),
        ),
      ),
      data: (pet) => _PetDetailContent(pet: pet),
    );
  }
}

class _PetDetailContent extends ConsumerWidget {
  const _PetDetailContent({required this.pet});
  final PetDetails pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(petPhotosProvider(pet.petId)).asData?.value;
    final summaries = ref.watch(myPetsProvider).asData?.value;
    final summary = summaries
        ?.where((item) => item.id == pet.petId)
        .firstOrNull;
    final mainPhoto =
        photos?.where((photo) => photo.isMain).firstOrNull ??
        photos?.firstOrNull;
    final imageUrl = mainPhoto?.url ?? summary?.mainPhotoUrl;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(AppRoutes.editPet(pet.petId)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: AppNetworkImage(url: imageUrl, fit: BoxFit.cover),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(pet.name, style: AppTypography.h1)),
                    const AppBadge(
                      label: 'Perfil activo',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    summary?.breedName ?? 'Raza #${pet.breedId}',
                    _genderLabel(pet.gender),
                    if (_age(pet.birthDate) case final age?)
                      '$age ${age == 1 ? 'año' : 'años'}',
                    if (pet.weight != null) '${pet.weight} kg',
                  ].join(' · '),
                  style: AppTypography.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.lg),
                _Tabs(
                  onPending: (label) {
                    if (label == 'Genealogía') {
                      context.push(AppRoutes.genealogyForPet(pet.petId));
                      return;
                    }
                    if (label == 'Matching') {
                      context.push(AppRoutes.matchingForPet(pet.petId));
                      return;
                    }
                    AppSnackBar.showInfo(
                      context,
                      '$label estará disponible próximamente.',
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Información', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: 'Especie',
                        value: summary?.speciesName ?? 'No disponible',
                      ),
                      _InfoRow(
                        icon: Icons.pets_outlined,
                        label: 'Raza',
                        value: summary?.breedName ?? 'Raza #${pet.breedId}',
                      ),
                      _InfoRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Fecha de nacimiento',
                        value: _date(pet.birthDate),
                      ),
                      _InfoRow(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Peso',
                        value: pet.weight == null
                            ? 'No registrado'
                            : '${pet.weight} kg',
                      ),
                      _InfoRow(
                        icon: Icons.palette_outlined,
                        label: 'Color',
                        value: pet.color ?? 'No registrado',
                      ),
                      _InfoRow(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Pedigree',
                        value: pet.pedigreeNumber ?? 'No registrado',
                      ),
                      _InfoRow(
                        icon: Icons.health_and_safety_outlined,
                        label: 'Esterilizado',
                        value: pet.isSterilized ? 'Sí' : 'No',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Descripción', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  pet.description ?? 'Sin descripción.',
                  style: AppTypography.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: 'Editar información',
                  icon: Icons.edit_outlined,
                  onPressed: () => context.push(AppRoutes.editPet(pet.petId)),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Fotos de ${pet.name}',
                  icon: Icons.photo_library_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => context.push(AppRoutes.petPhotos(pet.petId)),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.onPending});
  final ValueChanged<String> onPending;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Perfil', label: Text('Perfil')),
          ButtonSegment(value: 'Salud', label: Text('Salud')),
          ButtonSegment(value: 'Genealogía', label: Text('Genealogía')),
          ButtonSegment(value: 'Matching', label: Text('Matching')),
        ],
        selected: const {'Perfil'},
        showSelectedIcon: false,
        onSelectionChanged: (value) {
          if (value.first != 'Perfil') onPending(value.first);
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.caption),
                    Text(value, style: AppTypography.body),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}

String _genderLabel(String gender) =>
    gender.toUpperCase() == 'M' ? 'Macho' : 'Hembra';

int? _age(DateTime? birthDate) {
  if (birthDate == null) return null;
  final now = DateTime.now();
  var years = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    years--;
  }
  return years < 0 ? 0 : years;
}

String _date(DateTime? date) {
  if (date == null) return 'No registrada';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
