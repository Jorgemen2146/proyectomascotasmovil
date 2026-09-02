import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../matching/application/providers.dart';
import '../../application/providers.dart';
import '../../domain/entities/pet.dart';

class PetDetailPage extends ConsumerWidget {
  const PetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(petDetailsProvider(petId));
    return detail.when(
      loading: () => const _PetDetailLoading(),
      error: (_, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background),
        body: ErrorState(
          message: 'No pudimos cargar la información de esta mascota.',
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
    final matchingProfile = ref.watch(matchingProfileProvider(pet.petId));
    final isMatchingActive = switch (matchingProfile) {
      AsyncData(:final value) => value?.isActive,
      _ => null,
    };

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        key: const Key('petDetailScrollView'),
        slivers: [
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final photoHeight = (width * .54).clamp(190.0, 330.0);
                final profileHeight = (width * .50).clamp(190.0, 240.0);
                return _PetDetailHero(
                  pet: pet,
                  summary: summary,
                  imageUrl: imageUrl,
                  photoHeight: photoHeight,
                  profileHeight: profileHeight,
                  isMatchingActive: isMatchingActive,
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _PetInformation(
              pet: pet,
              summary: summary,
              onEdit: () => context.push(AppRoutes.editPet(pet.petId)),
              onPhotos: () => context.push(AppRoutes.petPhotos(pet.petId)),
              onMatching: () =>
                  context.push(AppRoutes.matchingForPet(pet.petId)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetDetailHero extends StatelessWidget {
  const _PetDetailHero({
    required this.pet,
    required this.summary,
    required this.imageUrl,
    required this.photoHeight,
    required this.profileHeight,
    required this.isMatchingActive,
  });

  final PetDetails pet;
  final PetSummary? summary;
  final String? imageUrl;
  final double photoHeight;
  final double profileHeight;
  final bool? isMatchingActive;

  @override
  Widget build(BuildContext context) {
    const tabsHeight = 68.0;
    const profileOverlap = 28.0;
    final safeTop = MediaQuery.paddingOf(context).top;
    final summaryText = _summary(pet, summary);
    final totalHeight = photoHeight - profileOverlap + profileHeight + 34;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: photoHeight,
            child: AppNetworkImage(url: imageUrl, fit: BoxFit.cover),
          ),
          Positioned(
            top: safeTop + AppSpacing.sm,
            left: AppSpacing.section,
            child: _PhotoAction(
              semanticsLabel: 'Volver',
              icon: AppIcons.back,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.pets);
                }
              },
            ),
          ),
          Positioned(
            top: safeTop + AppSpacing.sm,
            right: AppSpacing.section,
            child: _PhotoAction(
              semanticsLabel: 'Editar mascota',
              icon: AppIcons.edit,
              onTap: () => context.push(AppRoutes.editPet(pet.petId)),
            ),
          ),
          Positioned(
            top: photoHeight - profileOverlap,
            left: 0,
            right: 0,
            height: profileHeight,
            child: _PurpleProfileHeader(
              pet: pet,
              summaryText: summaryText,
              isMatchingActive: isMatchingActive,
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 0,
            height: tabsHeight,
            child: _PetTabs(petId: pet.petId),
          ),
        ],
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: AppColors.petDetailOverlay,
        shape: const CircleBorder(),
        child: InkWell(
          key: Key('petDetail$semanticsLabel'),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _PurpleProfileHeader extends StatelessWidget {
  const _PurpleProfileHeader({
    required this.pet,
    required this.summaryText,
    required this.isMatchingActive,
  });

  final PetDetails pet;
  final String summaryText;
  final bool? isMatchingActive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.petDetailAccentStart,
              AppColors.petDetailAccentEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 18,
              right: 34,
              child: _DecorativePaw(size: 58, opacity: .055),
            ),
            const Positioned(
              bottom: 22,
              right: 104,
              child: _DecorativePaw(size: 46, opacity: .045),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h1.copyWith(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isMatchingActive case final active?) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _ProfileStatusBadge(active: active),
                      ],
                    ],
                  ),
                  if (summaryText.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.compact),
                    Text(
                      summaryText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativePaw extends StatelessWidget {
  const _DecorativePaw({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Icon(
      AppIcons.pets,
      size: size,
      color: Colors.white.withValues(alpha: opacity),
    );
  }
}

class _ProfileStatusBadge extends StatelessWidget {
  const _ProfileStatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? AppColors.successSoft : AppColors.ageSoft,
        borderRadius: AppRadius.pillAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        child: Text(
          active ? 'Perfil activo' : 'Perfil inactivo',
          style: AppTypography.small.copyWith(
            color: active ? AppColors.success : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PetTabs extends StatelessWidget {
  const _PetTabs({required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillAll,
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            const Expanded(child: _PetTab(label: 'Perfil', selected: true)),
            Expanded(
              child: _PetTab(
                label: 'Salud',
                onTap: () => context.push(AppRoutes.healthForPet(petId)),
              ),
            ),
            Expanded(
              child: _PetTab(
                label: 'Genealogía',
                onTap: () => context.push(AppRoutes.genealogyForPet(petId)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetTab extends StatelessWidget {
  const _PetTab({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.petDetailAccentSoft : Colors.transparent,
        borderRadius: AppRadius.pillAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillAll,
          child: SizedBox(
            height: 56,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetInformation extends StatelessWidget {
  const _PetInformation({
    required this.pet,
    required this.summary,
    required this.onEdit,
    required this.onPhotos,
    required this.onMatching,
  });

  final PetDetails pet;
  final PetSummary? summary;
  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final VoidCallback onMatching;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.section,
        AppSpacing.xl,
        AppSpacing.section,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Información', style: AppTypography.h1.copyWith(fontSize: 23)),
          const SizedBox(height: AppSpacing.compact),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.petDetailAccent,
                borderRadius: AppRadius.pillAll,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _InformationGrid(
            cards: [
              _InfoCardData(
                icon: AppIcons.pets,
                label: 'Especie',
                value: summary?.speciesName ?? 'No disponible',
              ),
              _InfoCardData(
                icon: AppIcons.petsOutlined,
                label: 'Raza',
                value: summary?.breedName ?? 'No disponible',
              ),
              _InfoCardData(
                icon: AppIcons.calendar,
                label: 'Fecha de nacimiento',
                value: _date(pet.birthDate),
              ),
              _InfoCardData(
                icon: AppIcons.weight,
                label: 'Peso',
                value: _weight(pet.weight),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          _InfoCard(
            data: _InfoCardData(
              icon: AppIcons.palette,
              label: 'Color',
              value: _optional(pet.color),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Datos adicionales', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.compact),
          _InformationGrid(
            cards: [
              _InfoCardData(
                icon: AppIcons.pedigree,
                label: 'Pedigree',
                value: _optional(pet.pedigreeNumber),
              ),
              _InfoCardData(
                icon: AppIcons.sterilized,
                label: 'Esterilizado',
                value: pet.isSterilized ? 'Sí' : 'No',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          _DescriptionCard(description: pet.description),
          const SizedBox(height: AppSpacing.xl),
          _PetActionButton(
            label: 'Editar información',
            icon: AppIcons.edit,
            onTap: onEdit,
            primary: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PetActionButton(
            label: 'Fotos de ${pet.name}',
            icon: AppIcons.gallery,
            onTap: onPhotos,
          ),
          const SizedBox(height: AppSpacing.sm),
          _PetActionButton(
            label: 'Perfil de pareja',
            icon: AppIcons.matchingOutlined,
            onTap: onMatching,
          ),
        ],
      ),
    );
  }
}

class _InformationGrid extends StatelessWidget {
  const _InformationGrid({required this.cards});

  final List<_InfoCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 280;
        if (!twoColumns) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                _InfoCard(data: cards[index]),
                if (index != cards.length - 1)
                  const SizedBox(height: AppSpacing.compact),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.compact,
          runSpacing: AppSpacing.compact,
          children: [
            for (final card in cards)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.compact) / 2,
                child: _InfoCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _InfoCardData {
  const _InfoCardData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.data});

  final _InfoCardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 160;
        final iconSize = compact ? 40.0 : 48.0;
        return Container(
          key: Key('petInfo${data.label}'),
          constraints: const BoxConstraints(minHeight: 108),
          padding: EdgeInsets.all(compact ? AppSpacing.compact : AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardAll,
            border: Border.all(color: AppColors.border.withValues(alpha: .55)),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: const BoxDecoration(
                  color: AppColors.petDetailAccentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: AppColors.petDetailIcon,
                  size: compact ? 22 : 25,
                ),
              ),
              SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontSize: compact ? 10 : 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});

  final String? description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.petDetailAccentSoft.withValues(alpha: .48),
        borderRadius: AppRadius.cardAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Descripción', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _optional(description, fallback: 'Sin descripción.'),
            style: AppTypography.bodySecondary.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PetActionButton extends StatelessWidget {
  const _PetActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? Colors.white : AppColors.primary;
    return Material(
      color: primary ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: primary
            ? BorderSide.none
            : const BorderSide(color: AppColors.primary),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetDetailLoading extends StatelessWidget {
  const _PetDetailLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            height: MediaQuery.sizeOf(context).height * .42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.profileHeaderStart,
                  AppColors.petDetailAccentSoft,
                ],
              ),
            ),
          ),
          const Expanded(child: AppLoadingIndicator()),
        ],
      ),
    );
  }
}

String _summary(PetDetails pet, PetSummary? summary) {
  final parts = <String>[
    if (summary?.breedName.trim() case final breed? when breed.isNotEmpty)
      breed,
    ?_genderLabel(pet.gender),
    if (_age(pet.birthDate) case final age?)
      '$age ${age == 1 ? 'año' : 'años'}',
    if (pet.weight case final weight?) _weight(weight),
  ];
  return parts.join(' · ');
}

String? _genderLabel(String gender) => switch (gender.trim().toUpperCase()) {
  'M' || 'MALE' || 'MACHO' => 'Macho',
  'F' || 'FEMALE' || 'HEMBRA' => 'Hembra',
  _ => null,
};

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

String _weight(double? weight) {
  if (weight == null) return 'No registrado';
  return '${weight.toStringAsFixed(1)} kg';
}

String _optional(String? value, {String fallback = 'No registrado'}) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? fallback : normalized;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
