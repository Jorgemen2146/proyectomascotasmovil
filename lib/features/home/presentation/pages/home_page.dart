import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../authentication/application/auth_state_controller.dart';
import '../widgets/mock_pet.dart';
import '../widgets/pet_summary_card.dart';

/// First-iteration Home dashboard. Pet data is mocked purely to visualize
/// the design — Pets/Genealogy/Matching/Health remain placeholder routes.
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
    final firstName = authState.user?.fullName.trim().split(' ').first;

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
                  subtitle: '¿Cómo está ${mockPets.first.name} hoy?',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(AppIcons.notification),
                        onPressed: () => AppSnackBar.showInfo(
                          context,
                          'No tienes notificaciones nuevas.',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.logout),
                        onPressed: () => ref
                            .read(authStateControllerProvider.notifier)
                            .logout(),
                      ),
                    ],
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
              for (final (index, pet) in mockPets.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: 120 + index * 60),
                    child: PetSummaryCard(
                      pet: pet,
                      onTap: () => AppSnackBar.showInfo(
                        context,
                        'Próximamente disponible.',
                      ),
                    ),
                  ),
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
