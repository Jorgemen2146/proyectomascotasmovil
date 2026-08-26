import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
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
      appBar: AppBar(
        title: const Text('Buscar pareja'),
        actions: [
          IconButton(
            tooltip: 'Solicitudes',
            onPressed: () => context.push(AppRoutes.matchingRequests),
            icon: const Icon(Icons.inbox_outlined),
          ),
          IconButton(
            tooltip: 'Mis conexiones',
            onPressed: () => context.push(AppRoutes.matchingMatches),
            icon: const Icon(Icons.favorite_outline),
          ),
        ],
      ),
      body: pets.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, _) => ErrorState(
          message: 'No pudimos cargar tus mascotas.',
          onRetry: () => ref.invalidate(myPetsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.pets_outlined,
              title: 'Primero registra una mascota',
              message: 'Necesitas una mascota para comenzar a buscar pareja.',
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('matchingPetSelector'),
                  initialValue: selected,
                  decoration: const InputDecoration(labelText: 'Mi mascota'),
                  items: [
                    for (final item in items)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (value) => setState(() {
                    _petId = value;
                    _breedId = null;
                    _minimumAgeMonths = null;
                    _maximumAgeMonths = null;
                  }),
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
                  onFilters: () => _showFilters(pet),
                ),
              ],
            ),
          );
        },
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
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtros'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
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
          ],
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

class _ProfileAndSearch extends ConsumerWidget {
  const _ProfileAndSearch({
    required this.pet,
    required this.filters,
    required this.onFilters,
  });
  final PetSummary pet;
  final MatchingSearchFilters filters;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(matchingProfileProvider(pet.id));
    return profile.when(
      loading: () => const AppLoadingIndicator(),
      error: (_, _) => ErrorState(
        message: 'No pudimos consultar el perfil de ${pet.name}.',
        onRetry: () => ref.invalidate(matchingProfileProvider(pet.id)),
      ),
      data: (value) {
        if (value == null || !value.isActive) {
          return _InactiveProfile(pet: pet);
        }
        final candidates = ref.watch(matchingSearchProvider(filters));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Parejas sugeridas', style: AppTypography.h2),
                ),
                OutlinedButton.icon(
                  key: const Key('matchingFilters'),
                  onPressed: onFilters,
                  icon: const Icon(Icons.tune),
                  label: const Text('Filtros'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            candidates.when(
              loading: () => const AppLoadingIndicator(),
              error: (_, _) => ErrorState(
                message: 'No pudimos buscar parejas.',
                onRetry: () => ref.invalidate(matchingSearchProvider(filters)),
              ),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No encontramos parejas con estos filtros.',
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
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${widget.pet.name} aún no está visible', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.sm),
        const Text('Activa su perfil para encontrar posibles parejas.'),
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
          ref
              .watch(breedsProvider(widget.pet.speciesId))
              .when(
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
                  onChanged: (value) =>
                      setState(() => _preferredBreedId = value),
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
                    labelText: 'Edad mínima (opcional)',
                    helperText: 'Meses',
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
                    labelText: 'Edad máxima (opcional)',
                    helperText: 'Meses',
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
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNetworkImage(
          url: candidate.mainPhotoUrl,
          height: 220,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
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
                  Chip(label: Text('${candidate.compatibilityScore}%')),
                ],
              ),
              Text(candidate.breedName, style: AppTypography.bodySecondary),
              Text('${_age(candidate.ageMonths)} · ${_sex(candidate.sex)}'),
              if (candidate.hasPedigree) ...[
                const SizedBox(height: AppSpacing.sm),
                const Chip(label: Text('Pedigree')),
              ],
              if (candidate.hasKnownRelationship) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: .12),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
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
  );
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
