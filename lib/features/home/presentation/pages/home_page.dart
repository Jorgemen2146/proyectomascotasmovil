import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../authentication/application/auth_state_controller.dart';
import '../../../pets/application/providers.dart';
import '../widgets/pet_summary_card.dart';

/// Home dashboard backed by the same data as the full Pets screen.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _navItems = [
    AppBottomNavItem(
      icon: AppIcons.homeOutlined,
      selectedIcon: AppIcons.home,
      label: 'Inicio',
    ),
    AppBottomNavItem(
      icon: AppIcons.petsOutlined,
      selectedIcon: AppIcons.pets,
      label: 'Mascotas',
    ),
    AppBottomNavItem(
      icon: AppIcons.healthOutlined,
      selectedIcon: AppIcons.health,
      label: 'Salud',
    ),
    AppBottomNavItem(
      icon: AppIcons.profileOutlined,
      selectedIcon: AppIcons.profile,
      label: 'Perfil',
    ),
  ];

  static const _navRoutes = [
    AppRoutes.home,
    AppRoutes.pets,
    AppRoutes.health,
    AppRoutes.profile,
  ];

  void _onNavTap(BuildContext context, int index) {
    if (index == 0) return;
    context.push(_navRoutes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateControllerProvider);
    final pets = ref.watch(myPetsProvider);
    final firstName = authState.user?.fullName.trim().split(' ').first;
    final loadedPets = pets.asData?.value;
    final firstPetName = loadedPets == null || loadedPets.isEmpty
        ? null
        : loadedPets.first.name;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 600,
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            children: [
              FadeSlideIn(
                child: AppTopBar(
                  title: '¡Hola, ${firstName ?? 'amigo'}! 👋',
                  subtitle: firstPetName == null
                      ? '¿Cómo están tus mascotas hoy?'
                      : '¿Cómo está $firstPetName hoy?',
                  trailing: IconButton(
                    icon: const Icon(AppIcons.notification),
                    onPressed: () => AppSnackBar.showInfo(
                      context,
                      'No tienes notificaciones nuevas.',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: SectionTitle(
                  title: 'Mis Mascotas',
                  trailing: IconButton(
                    icon: const Icon(AppIcons.addCircle),
                    onPressed: () => context.push(AppRoutes.newPet),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...pets.when(
                loading: () => const [
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (error, _) => [
                  ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(myPetsProvider),
                  ),
                ],
                data: (items) => items.isEmpty
                    ? [
                        EmptyState(
                          icon: Icons.pets_outlined,
                          title: 'Aún no tienes mascotas',
                          message: 'Agrega tu primera mascota',
                          actionLabel: 'Agregar mascota',
                          onAction: () => context.push(AppRoutes.newPet),
                        ),
                      ]
                    : [
                        for (final (index, pet) in items.indexed)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: FadeSlideIn(
                              delay: Duration(milliseconds: 120 + index * 60),
                              child: PetSummaryCard(
                                pet: pet,
                                onTap: () =>
                                    context.push(AppRoutes.petDetails(pet.id)),
                              ),
                            ),
                          ),
                      ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        items: _navItems,
        currentIndex: 0,
        onTap: (index) => _onNavTap(context, index),
      ),
    );
  }
}
