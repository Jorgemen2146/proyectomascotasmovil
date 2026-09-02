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
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/main_bottom_navigation.dart';
import '../../../pets/application/providers.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../application/providers.dart';
import '../../domain/entities/matching.dart';

class MatchingPage extends ConsumerStatefulWidget {
  const MatchingPage({super.key, this.initialPetId});
  final String? initialPetId;

  @override
  ConsumerState<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends ConsumerState<MatchingPage> {
  String? _petId;
  int? _breedId;
  int? _minimumAgeMonths;
  int? _maximumAgeMonths;

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(myPetsProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: pets.when(
              loading: () => const _MatchingSkeleton(),
              error: (_, _) => ErrorState(
                message: 'No pudimos cargar tus mascotas.',
                onRetry: () => ref.invalidate(myPetsProvider),
              ),
              data: _content,
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 2),
    );
  }

  Widget _content(List<PetSummary> items) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.section),
        children: [
          const _MatchingHeader(),
          const SizedBox(height: 72),
          EmptyState(
            icon: AppIcons.petsOutlined,
            title: 'Aún no tienes mascotas',
            message: 'Agrega una mascota para empezar a buscar pareja.',
            actionLabel: 'Agregar mascota',
            onAction: () => context.push(AppRoutes.newPet),
          ),
        ],
      );
    }
    final requested = _petId ?? widget.initialPetId;
    final selected = items.any((pet) => pet.id == requested)
        ? requested!
        : items.first.id;
    final pet = items.firstWhere((item) => item.id == selected);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(matchingProfileProvider(selected));
        ref.invalidate(matchingSearchProvider);
      },
      child: ListView(
        key: const Key('matchingScrollView'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.section,
          AppSpacing.md,
          AppSpacing.section,
          AppSpacing.lg,
        ),
        children: [
          const _MatchingHeader(),
          const SizedBox(height: AppSpacing.lg),
          const _MatchingSectionNavigation(selectedIndex: 0),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '¿Para cuál mascota buscas pareja?',
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.compact),
          SizedBox(
            height: 128,
            child: ListView.separated(
              key: const Key('matchingPetSelector'),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.compact),
              itemBuilder: (_, index) {
                final item = items[index];
                return _PetSelectorCard(
                  pet: item,
                  selected: item.id == selected,
                  onTap: () => setState(() {
                    _petId = item.id;
                    _breedId = null;
                    _minimumAgeMonths = null;
                    _maximumAgeMonths = null;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileAndSearch(
            pet: pet,
            filters: MatchingSearchFilters(
              petId: selected,
              breedId: _breedId,
              minimumAgeMonths: _minimumAgeMonths,
              maximumAgeMonths: _maximumAgeMonths,
            ),
            hasFilters:
                _breedId != null ||
                _minimumAgeMonths != null ||
                _maximumAgeMonths != null,
            onFilters: () => _showFilters(pet),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilters(PetSummary pet) async {
    var minimumAge = _minimumAgeMonths?.toString() ?? '';
    var maximumAge = _maximumAgeMonths?.toString() ?? '';
    int? parsedMinimumAge;
    int? parsedMaximumAge;
    String? ageError;
    var breed = _breedId;
    final breeds = await ref.read(breedsProvider(pet.speciesId).future);
    if (!mounted) return;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.compact,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppRadius.pillAll,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Filtrar parejas', style: AppTypography.h2),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<int?>(
                  initialValue: breed,
                  decoration: const InputDecoration(labelText: 'Raza'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    for (final item in breeds)
                      DropdownMenuItem(
                        value: item.breedId,
                        child: Text(item.name),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => breed = value),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('matchingFilterMinimumAge'),
                  initialValue: minimumAge,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad mínima (opcional)',
                    helperText: 'Meses',
                  ),
                  onChanged: (value) => minimumAge = value,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('matchingFilterMaximumAge'),
                  initialValue: maximumAge,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad máxima (opcional)',
                    helperText: 'Meses',
                  ),
                  onChanged: (value) => maximumAge = value,
                ),
                if (ageError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ageError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          breed = null;
                          minimumAge = '';
                          maximumAge = '';
                          parsedMinimumAge = null;
                          parsedMaximumAge = null;
                          Navigator.pop(context, true);
                        },
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.compact),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final validation = _validateOptionalAges(
                            minimumAge,
                            maximumAge,
                          );
                          if (validation.error case final error?) {
                            setDialogState(() => ageError = error);
                            return;
                          }
                          parsedMinimumAge = validation.minimum;
                          parsedMaximumAge = validation.maximum;
                          Navigator.pop(context, true);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (accepted == true) {
      setState(() {
        _breedId = breed;
        _minimumAgeMonths = parsedMinimumAge;
        _maximumAgeMonths = parsedMaximumAge;
      });
    }
  }
}

class _MatchingHeader extends StatelessWidget {
  const _MatchingHeader();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(AppIcons.matching, color: AppColors.primary),
      ),
      const SizedBox(width: AppSpacing.compact),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buscar pareja', style: AppTypography.screenTitle),
            Text(
              'Encuentra una pareja compatible para tu mascota',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    ],
  );
}

class _MatchingSectionNavigation extends StatelessWidget {
  const _MatchingSectionNavigation({required this.selectedIndex});
  final int selectedIndex;
  @override
  Widget build(BuildContext context) {
    const labels = ['Descubrir', 'Solicitudes', 'Matches'];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Row(
        children: [
          for (final (index, label) in labels.indexed)
            Expanded(
              child: Material(
                color: index == selectedIndex
                    ? AppColors.surface
                    : Colors.transparent,
                borderRadius: AppRadius.smAll,
                child: InkWell(
                  key: Key('matchingSection$index'),
                  borderRadius: AppRadius.smAll,
                  onTap: index == selectedIndex
                      ? null
                      : () => context.push(
                          index == 1
                              ? AppRoutes.matchingRequests
                              : AppRoutes.matchingMatches,
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppTypography.small.copyWith(
                        color: index == selectedIndex
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: index == selectedIndex
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PetSelectorCard extends StatelessWidget {
  const _PetSelectorCard({
    required this.pet,
    required this.selected,
    required this.onTap,
  });
  final PetSummary pet;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: AppRadius.lgAll,
    child: InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Container(
        width: 224,
        padding: const EdgeInsets.all(AppSpacing.compact),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: [
            AppNetworkImage(
              url: pet.mainPhotoUrl,
              width: 72,
              height: 88,
              borderRadius: AppRadius.mdAll,
            ),
            const SizedBox(width: AppSpacing.compact),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle,
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                  Text(
                    pet.breedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_sex(pet.sex)} · ${_petAge(pet)}',
                    maxLines: 1,
                    style: AppTypography.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileAndSearch extends ConsumerWidget {
  const _ProfileAndSearch({
    required this.pet,
    required this.filters,
    required this.hasFilters,
    required this.onFilters,
  });
  final PetSummary pet;
  final MatchingSearchFilters filters;
  final bool hasFilters;
  final VoidCallback onFilters;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(matchingProfileProvider(pet.id));
    return profile.when(
      loading: () => const _InlineSkeleton(),
      error: (_, _) => ErrorState(
        message: 'No pudimos consultar el perfil de ${pet.name}.',
        onRetry: () => ref.invalidate(matchingProfileProvider(pet.id)),
      ),
      data: (value) {
        if (value == null || !value.isActive) return _InactiveProfile(pet: pet);
        final candidates = ref.watch(matchingSearchProvider(filters));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Parejas recomendadas',
                    style: AppTypography.sectionTitle,
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('matchingFilters'),
                  onPressed: onFilters,
                  icon: Icon(
                    hasFilters ? Icons.filter_alt : Icons.tune_rounded,
                    size: 18,
                  ),
                  label: const Text('Filtros'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            candidates.when(
              loading: () => const _CandidateSkeleton(),
              error: (_, _) => ErrorState(
                message: 'No pudimos buscar parejas en este momento.',
                onRetry: () => ref.invalidate(matchingSearchProvider(filters)),
              ),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No encontramos parejas',
                      message: 'Prueba con criterios más amplios.',
                    )
                  : Column(
                      children: [
                        for (final candidate in items) ...[
                          _CandidateCard(
                            sourcePetId: pet.id,
                            candidate: candidate,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _InactiveProfile extends ConsumerStatefulWidget {
  const _InactiveProfile({required this.pet});
  final PetSummary pet;
  @override
  ConsumerState<_InactiveProfile> createState() => _InactiveProfileState();
}

class _InactiveProfileState extends ConsumerState<_InactiveProfile> {
  bool _editing = false;
  bool _allowMixedBreed = true;
  String _sex = 'F';
  int? _preferredBreedId;
  final _description = TextEditingController();
  final _minimumAge = TextEditingController();
  final _maximumAge = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    _minimumAge.dispose();
    _maximumAge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.section),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryFaint, AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: AppRadius.cardAll,
      border: Border.all(color: AppColors.primarySoft),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(AppIcons.matching, color: AppColors.primary, size: 34),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Activa su perfil',
          textAlign: TextAlign.center,
          style: AppTypography.h2,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${widget.pet.name} aún no está visible',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Completa la información necesaria para empezar a encontrar parejas compatibles.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySecondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (!_editing)
          AppButton.primary(
            key: const Key('activateMatchingProfile'),
            label: 'Activar perfil',
            onPressed: () => setState(() => _editing = true),
          )
        else ...[
          DropdownButtonFormField<String>(
            initialValue: _sex,
            decoration: const InputDecoration(labelText: 'Sexo buscado'),
            items: const [
              DropdownMenuItem(value: 'F', child: Text('Hembra')),
              DropdownMenuItem(value: 'M', child: Text('Macho')),
            ],
            onChanged: (value) => setState(() => _sex = value ?? 'F'),
          ),
          const SizedBox(height: AppSpacing.md),
          ref.watch(breedsProvider(widget.pet.speciesId)).when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('No pudimos cargar las razas.'),
            data: (breeds) => DropdownButtonFormField<int?>(
              initialValue: _preferredBreedId,
              decoration: const InputDecoration(
                labelText: 'Raza preferida (opcional)',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Sin preferencia'),
                ),
                for (final breed in breeds)
                  DropdownMenuItem(
                    value: breed.breedId,
                    child: Text(breed.name),
                  ),
              ],
              onChanged: (value) => setState(() => _preferredBreedId = value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('matchingProfileMinimumAge'),
                  controller: _minimumAge,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad mínima',
                    helperText: 'Opcional · meses',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  key: const Key('matchingProfileMaximumAge'),
                  controller: _maximumAge,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Edad máxima',
                    helperText: 'Opcional · meses',
                  ),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _allowMixedBreed,
            title: const Text('Permitir otras razas'),
            onChanged: (value) => setState(() => _allowMixedBreed = value),
          ),
          TextField(
            controller: _description,
            maxLength: 1000,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          AppButton.primary(
            label: 'Guardar y activar',
            isLoading: ref.watch(matchingControllerProvider),
            onPressed: _activate,
          ),
        ],
      ],
    ),
  );

  Future<void> _activate() async {
    final ages = _validateOptionalAges(_minimumAge.text, _maximumAge.text);
    if (ages.error case final error?) {
      AppSnackBar.showError(context, error);
      return;
    }
    final result = await ref
        .read(matchingControllerProvider.notifier)
        .createProfile(
          MatchingProfileDraft(
            petId: widget.pet.id,
            lookingForSex: _sex,
            allowMixedBreed: _allowMixedBreed,
            preferredBreedId: _preferredBreedId,
            minimumAgeMonths: ages.minimum,
            maximumAgeMonths: ages.maximum,
            description: _description.text,
          ),
        );
    if (!mounted) return;
    result.when(
      success: (_) => AppSnackBar.showSuccess(context, 'Perfil activado.'),
      failure: (failure) => AppSnackBar.showError(context, failure.message),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.sourcePetId, required this.candidate});
  final String sourcePetId;
  final MatchingCandidate candidate;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.cardAll,
      border: Border.all(color: AppColors.border.withValues(alpha: .75)),
      boxShadow: AppShadows.card,
    ),
    child: ClipRRect(
      borderRadius: AppRadius.cardAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNetworkImage(url: candidate.mainPhotoUrl, height: 220),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(candidate.name, style: AppTypography.h2),
                    ),
                    _InfoChip(
                      label: '${candidate.compatibilityScore}% compatible',
                      emphasized: true,
                    ),
                  ],
                ),
                Text(candidate.breedName, style: AppTypography.bodySecondary),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoChip(label: _sex(candidate.sex)),
                    _InfoChip(label: _age(candidate.ageMonths)),
                    if (candidate.hasPedigree)
                      const _InfoChip(label: 'Pedigree'),
                  ],
                ),
                if (candidate.hasKnownRelationship) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.compact),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: .10),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text('Existe parentesco registrado')),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: 'Ver perfil',
                  onPressed: () => context.push(
                    AppRoutes.matchingCandidate(sourcePetId, candidate.petId),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.emphasized = false});
  final String label;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: emphasized ? AppColors.primarySoft : AppColors.ageSoft,
      borderRadius: AppRadius.pillAll,
    ),
    child: Text(
      label,
      style: AppTypography.small.copyWith(
        color: emphasized ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _MatchingSkeleton extends StatelessWidget {
  const _MatchingSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(AppSpacing.section),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(width: 230, height: 24),
        SizedBox(height: AppSpacing.sm),
        _SkeletonBox(width: 300, height: 14),
        SizedBox(height: AppSpacing.xl),
        _SkeletonBox(height: 46),
        SizedBox(height: AppSpacing.xl),
        _SkeletonBox(width: 250, height: 18),
        SizedBox(height: AppSpacing.md),
        _SkeletonBox(height: 128),
      ],
    ),
  );
}

class _InlineSkeleton extends StatelessWidget {
  const _InlineSkeleton();
  @override
  Widget build(BuildContext context) => const _SkeletonBox(height: 170);
}

class _CandidateSkeleton extends StatelessWidget {
  const _CandidateSkeleton();
  @override
  Widget build(BuildContext context) => const _SkeletonBox(height: 350);
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({this.width = double.infinity, required this.height});
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.ageSoft,
      borderRadius: AppRadius.lgAll,
    ),
  );
}

String _petAge(PetSummary pet) {
  final years = pet.ageYears;
  if (years == null) return 'Edad no indicada';
  return '$years ${years == 1 ? 'año' : 'años'}';
}

String _age(int months) => months < 12
    ? '$months meses'
    : '${months ~/ 12} ${months ~/ 12 == 1 ? 'año' : 'años'}';
String _sex(String value) => value.toUpperCase() == 'F' ? 'Hembra' : 'Macho';

({int? minimum, int? maximum, String? error}) _validateOptionalAges(
  String minimumText,
  String maximumText,
) {
  final minimumValue = minimumText.trim();
  final maximumValue = maximumText.trim();
  final minimum = minimumValue.isEmpty ? null : int.tryParse(minimumValue);
  final maximum = maximumValue.isEmpty ? null : int.tryParse(maximumValue);
  if ((minimumValue.isNotEmpty && minimum == null) ||
      (maximumValue.isNotEmpty && maximum == null)) {
    return (
      minimum: null,
      maximum: null,
      error: 'Ingresa las edades en meses usando números válidos.',
    );
  }
  if ((minimum != null && minimum < 0) || (maximum != null && maximum < 0)) {
    return (
      minimum: minimum,
      maximum: maximum,
      error: 'Las edades no pueden ser negativas.',
    );
  }
  if (minimum != null && maximum != null && minimum > maximum) {
    return (
      minimum: minimum,
      maximum: maximum,
      error: 'La edad mínima no puede ser mayor que la máxima.',
    );
  }
  return (minimum: minimum, maximum: maximum, error: null);
}
