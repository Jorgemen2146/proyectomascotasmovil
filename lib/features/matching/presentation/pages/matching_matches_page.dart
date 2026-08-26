import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/providers.dart';
import '../../domain/entities/matching.dart';

class MatchingMatchesPage extends ConsumerWidget {
  const MatchingMatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis conexiones')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(matchesProvider),
        child: matches.when(
          loading: () => const AppLoadingIndicator(),
          error: (_, _) => ErrorState(
            message: 'No pudimos cargar tus conexiones.',
            onRetry: () => ref.invalidate(matchesProvider),
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 140),
                    EmptyState(
                      icon: Icons.favorite_border,
                      title: 'Todavía no tienes conexiones.',
                      message: 'Los matches aceptados aparecerán aquí.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, index) => _MatchCard(items[index]),
                ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard(this.match);
  final PetMatch match;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PetAvatar(match.pet1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Icon(Icons.favorite),
            ),
            _PetAvatar(match.pet2),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${match.pet1.name} ↔ ${match.pet2.name}',
          style: AppTypography.h3,
        ),
        const Text('Match aceptado'),
        const SizedBox(height: AppSpacing.md),
        AppButton.primary(
          label: 'Ver conexión',
          onPressed: () => context.push(AppRoutes.matchingMatch(match.matchId)),
        ),
      ],
    ),
  );
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar(this.pet);
  final PublicMatchingPet pet;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppNetworkImage(
        url: pet.mainPhotoUrl,
        width: 72,
        height: 72,
        borderRadius: BorderRadius.circular(36),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(pet.name),
    ],
  );
}
