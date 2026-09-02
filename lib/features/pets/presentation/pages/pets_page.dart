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
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/main_bottom_navigation.dart';
import '../../application/providers.dart';
import '../../domain/entities/pet.dart';
import '../widgets/pet_design_widgets.dart';

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
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.section,
              ),
              child: Column(
                children: [
                  _PetsHeader(onAdd: () => context.push(AppRoutes.newPet)),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    key: const Key('petSearchField'),
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar mascota...',
                      prefixIcon: Icon(AppIcons.search),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  pets.when(
                    loading: () => const SizedBox(height: 42),
                    error: (_, _) => const SizedBox(height: 42),
                    data: (items) => _FilterBar(
                      pets: items,
                      selected: _filter,
                      onSelected: (value) => setState(() => _filter = value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: _buildContent(pets)),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.pillAll,
          boxShadow: AppShadows.floatingBlue,
        ),
        child: FloatingActionButton.extended(
          key: const Key('addPetFloatingButton'),
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          onPressed: () => context.push(AppRoutes.newPet),
          icon: const Icon(AppIcons.add),
          label: Text('Agregar mascota', style: AppTypography.button),
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildContent(AsyncValue<List<PetSummary>> pets) {
    return pets.when(
      loading: () => const AppLoadingIndicator(),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(myPetsProvider),
      ),
      data: (items) {
        final filtered = _filterPets(items);
        if (filtered.isEmpty) {
          return EmptyState(
            icon: AppIcons.petsOutlined,
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
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: filtered.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.compact),
            itemBuilder: (_, index) {
              final pet = filtered[index];
              return PetDesignCard(
                pet: pet,
                onTap: () => context.push(AppRoutes.petDetails(pet.id)),
              );
            },
          ),
        );
      },
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
          return matchesSearch && _matchesFilter(pet, _filter);
        })
        .toList(growable: false);
  }
}

class _PetsHeader extends StatelessWidget {
  const _PetsHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          IconButton(
            key: const Key('petsBackButton'),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRoutes.home),
            icon: const Icon(AppIcons.back),
          ),
          Expanded(
            child: Text(
              'Mis Mascotas',
              textAlign: TextAlign.center,
              style: AppTypography.screenTitle,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.floatingBlue,
            ),
            child: IconButton(
              key: const Key('petsAddButton'),
              onPressed: onAdd,
              color: Colors.white,
              icon: const Icon(AppIcons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.pets,
    required this.selected,
    required this.onSelected,
  });

  final List<PetSummary> pets;
  final _PetFilter selected;
  final ValueChanged<_PetFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final counts = {
      _PetFilter.all: pets.length,
      _PetFilter.dogs: pets
          .where((pet) => _matchesFilter(pet, _PetFilter.dogs))
          .length,
      _PetFilter.cats: pets
          .where((pet) => _matchesFilter(pet, _PetFilter.cats))
          .length,
    };
    return Row(
      children: [
        for (final filter in _PetFilter.values) ...[
          Flexible(
            child: _FilterChip(
              label: switch (filter) {
                _PetFilter.all => 'Todas',
                _PetFilter.dogs => 'Perros',
                _PetFilter.cats => 'Gatos',
              },
              count: counts[filter]!,
              selected: selected == filter,
              onTap: () => onSelected(filter),
            ),
          ),
          if (filter != _PetFilter.values.last)
            const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        key: Key('petFilter${label.toLowerCase()}'),
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                count.toString(),
                style: AppTypography.small.copyWith(
                  color: selected
                      ? Colors.white.withValues(alpha: .82)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _matchesFilter(PetSummary pet, _PetFilter filter) {
  final species = pet.speciesName.toLowerCase();
  return switch (filter) {
    _PetFilter.all => true,
    _PetFilter.dogs => species.contains('perro') || species.contains('dog'),
    _PetFilter.cats => species.contains('gato') || species.contains('cat'),
  };
}
