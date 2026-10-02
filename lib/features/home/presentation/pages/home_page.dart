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
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/main_bottom_navigation.dart';
import '../../../authentication/application/auth_state_controller.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../pets/application/providers.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../../pets/presentation/widgets/pet_design_widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateControllerProvider).user;
    final firstName = user?.fullName.trim().split(RegExp(r'\s+')).first;
    final pets = ref.watch(myPetsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(myPetsProvider.future),
              child: ListView(
                key: const Key('homeScrollView'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.section,
                  AppSpacing.section,
                  AppSpacing.section,
                  AppSpacing.lg,
                ),
                children: [
                  _HomeHeader(firstName: firstName),
                  const SizedBox(height: AppSpacing.lg),
                  pets.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => ErrorState(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(myPetsProvider),
                    ),
                    data: (items) => _HomePetsContent(pets: items),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.firstName});

  final String? firstName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, ${firstName?.isNotEmpty == true ? firstName : 'amigo'}! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Qué bueno verte de nuevo',
                style: AppTypography.bodySecondary,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const NotificationBell(),
      ],
    );
  }
}

class _HomePetsContent extends StatelessWidget {
  const _HomePetsContent({required this.pets});

  final List<PetSummary> pets;

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return Column(
        children: [
          EmptyState(
            icon: AppIcons.petsOutlined,
            title: 'Aún no tienes mascotas',
            message: 'Agrega tu primera mascota',
            actionLabel: 'Agregar mascota',
            onAction: () => context.push(AppRoutes.newPet),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _HealthCallToAction(),
        ],
      );
    }

    final featured = pets.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeaturedPetCard(
          pet: featured,
          onTap: () => context.push(AppRoutes.petDetails(featured.id)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text('Mis mascotas', style: AppTypography.sectionTitle),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.pets),
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final pet in pets.take(3)) ...[
          PetDesignCard(
            pet: pet,
            compact: true,
            onTap: () => context.push(AppRoutes.petDetails(pet.id)),
          ),
          const SizedBox(height: AppSpacing.compact),
        ],
        const SizedBox(height: AppSpacing.xs),
        _HealthCallToAction(petId: featured.id),
      ],
    );
  }
}

class _FeaturedPetCard extends StatelessWidget {
  const _FeaturedPetCard({required this.pet, required this.onTap});

  final PetSummary pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isMale = pet.sex.toUpperCase() == 'M';
    final age = pet.ageYears;
    final cardHeight = MediaQuery.sizeOf(context).width < 360 ? 212.0 : 190.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.heroStart, AppColors.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.floatingBlue,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('featuredPetCard'),
          onTap: onTap,
          borderRadius: AppRadius.cardAll,
          child: ClipRRect(
            borderRadius: AppRadius.cardAll,
            child: SizedBox(
              height: cardHeight,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: 185,
                    child: AppNetworkImage(
                      url: pet.mainPhotoUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: 220,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.heroStart,
                            AppColors.heroStart.withValues(alpha: .18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.section),
                    child: FractionallySizedBox(
                      widthFactor: .62,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h1.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            pet.breedName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .18),
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                [
                                  if (age != null)
                                    '$age ${age == 1 ? 'año' : 'años'}',
                                  isMale ? 'Macho' : 'Hembra',
                                ].join(' · '),
                                style: AppTypography.small.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'En PetLife desde',
                            style: AppTypography.small.copyWith(
                              color: Colors.white.withValues(alpha: .78),
                            ),
                          ),
                          Text(
                            pet.createdAt.year.toString(),
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.compact,
                    right: AppSpacing.compact,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Icon(
                          AppIcons.health,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HealthCallToAction extends StatelessWidget {
  const _HealthCallToAction({this.petId});

  final String? petId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.lgAll,
            ),
            child: const Icon(
              AppIcons.calendar,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Listo para el cuidado?', style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Registra la salud y vacunas de tus mascotas.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    backgroundColor: AppColors.primarySoft,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => context.push(
                    petId == null
                        ? AppRoutes.health
                        : AppRoutes.healthForPet(petId!),
                  ),
                  icon: const Icon(AppIcons.chevronRight, size: 16),
                  label: const Text('Ir a Salud'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
