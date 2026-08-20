import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/main_bottom_navigation.dart';
import '../../application/providers.dart';
import '../../domain/entities/pet.dart';

enum _PetFilter { all, dogs, cats }

class PetsPage extends ConsumerStatefulWidget {
  const PetsPage({super.key});

  @override
  ConsumerState<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends ConsumerState<PetsPage> {
  final _searchController = TextEditingController();
  _PetFilter _filter = _PetFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(myPetsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Mascotas')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              TextField(
                key: const Key('petSearchField'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar mascota...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<_PetFilter>(
                  segments: const [
                    ButtonSegment(value: _PetFilter.all, label: Text('Todas')),
                    ButtonSegment(
                      value: _PetFilter.dogs,
                      label: Text('Perros'),
                    ),
                    ButtonSegment(value: _PetFilter.cats, label: Text('Gatos')),
                  ],
                  selected: {_filter},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _filter = value.first),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: pets.when(
                  loading: () => const AppLoadingIndicator(),
                  error: (error, _) => ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(myPetsProvider),
                  ),
                  data: (items) {
                    final filtered = _filterPets(items);
                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.pets_outlined,
                        title: items.isEmpty
                            ? 'Aún no tienes mascotas'
                            : 'No encontramos mascotas',
                        message: items.isEmpty
                            ? 'Agrega tu primera mascota'
                            : 'Prueba con otra búsqueda o filtro.',
                        actionLabel: items.isEmpty ? 'Agregar mascota' : null,
                        onAction: items.isEmpty
                            ? () => context.push(AppRoutes.newPet)
                            : null,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.refresh(myPetsProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, index) => _PetCard(
                          pet: filtered[index],
                          onTap: () => context.push(
                            AppRoutes.petDetails(filtered[index].id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newPet),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 1),
    );
  }

  List<PetSummary> _filterPets(List<PetSummary> pets) {
    final search = _searchController.text.trim().toLowerCase();
    return pets
        .where((pet) {
          final matchesSearch =
              search.isEmpty ||
              pet.name.toLowerCase().contains(search) ||
              pet.breedName.toLowerCase().contains(search);
          final species = pet.speciesName.toLowerCase();
          final matchesFilter = switch (_filter) {
            _PetFilter.all => true,
            _PetFilter.dogs =>
              species.contains('perro') || species.contains('dog'),
            _PetFilter.cats =>
              species.contains('gato') || species.contains('cat'),
          };
          return matchesSearch && matchesFilter;
        })
        .toList(growable: false);
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.onTap});
  final PetSummary pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final age = pet.ageYears;
    final sex = pet.sex.toUpperCase() == 'M' ? 'Macho' : 'Hembra';
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppNetworkImage(
            url: pet.mainPhotoUrl,
            width: 72,
            height: 72,
            borderRadius: AppRadius.mdAll,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: AppTypography.h3),
                Text(pet.breedName, style: AppTypography.bodySecondary),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    if (age != null) '$age ${age == 1 ? 'año' : 'años'}',
                    sex,
                  ].join(' · '),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
