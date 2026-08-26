import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/providers.dart';
import '../../domain/entities/matching.dart';

class MatchingMatchDetailPage extends ConsumerWidget {
  const MatchingMatchDetailPage({super.key, required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchDetailProvider(matchId));
    return Scaffold(
      appBar: AppBar(title: const Text('Conexión')),
      body: match.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, _) => ErrorState(
          message: 'No pudimos cargar la conexión.',
          onRetry: () => ref.invalidate(matchDetailProvider(matchId)),
        ),
        data: (value) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Icon(Icons.favorite, size: 52, color: AppColors.error),
              Text(
                '¡Es un match!',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Pet(value.pet1),
                  const Icon(Icons.swap_horiz, color: AppColors.primary),
                  _Pet(value.pet2),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Información de contacto', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              _ContactCard(contact: value.pet1Owner, petName: value.pet1.name),
              const SizedBox(height: AppSpacing.sm),
              _ContactCard(contact: value.pet2Owner, petName: value.pet2.name),
              const SizedBox(height: AppSpacing.xl),
              Text('Posible camada', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              _BreedingIntentSection(matchId: matchId),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(matchDetailProvider(matchId));
    await ref.read(matchDetailProvider(matchId).future);
  }
}

class _Pet extends StatelessWidget {
  const _Pet(this.pet);
  final PublicMatchingPet pet;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppNetworkImage(
        url: pet.mainPhotoUrl,
        width: 100,
        height: 100,
        borderRadius: BorderRadius.circular(50),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(pet.name, style: AppTypography.h3),
    ],
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.petName});
  final SharedOwnerContact contact;
  final String petName;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Criador de $petName', style: AppTypography.h3),
        Text(contact.displayName ?? 'Nombre no compartido'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          contact.phoneNumber ?? 'El propietario no ha compartido su teléfono.',
        ),
      ],
    ),
  );
}

class _BreedingIntentSection extends ConsumerWidget {
  const _BreedingIntentSection({required this.matchId});
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intent = ref.watch(breedingIntentProvider(matchId));
    return intent.when(
      loading: () => const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, _) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('No pudimos actualizar la intención de camada.'),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Reintentar',
              variant: AppButtonVariant.outlined,
              onPressed: () => ref.invalidate(breedingIntentProvider(matchId)),
            ),
          ],
        ),
      ),
      data: (value) => _content(context, ref, value),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, BreedingIntent? value) {
    if (value == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¿Están considerando una futura camada?'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esto solo registra una intención. No confirma embarazo ni camada.',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              key: const Key('proposeBreedingIntent'),
              label: 'Proponer camada',
              onPressed: () => _propose(context, ref),
            ),
          ],
        ),
      );
    }
    final notes = value.notes;
    final expectedDate = value.expectedDateUtc;
    final acceptedAt = value.acceptedAtUtc;
    final cancelledAt = value.cancelledAtUtc;
    final isProposed = value.status == 'Proposed';
    final isAgreed = value.status == 'Agreed';
    final isCancelled = value.status == 'Cancelled';
    final isCompleted = value.status == 'Completed';
    final title = switch (value.status) {
      'Proposed' when value.proposedByCurrentUser => 'Propuesta enviada',
      'Proposed' => 'Propuesta de posible camada',
      'Agreed' => 'Intención de camada acordada',
      'Cancelled' => 'Intención cancelada',
      'Completed' => 'Intención completada',
      _ => 'Posible camada',
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.h3.copyWith(
              color: isAgreed
                  ? AppColors.success
                  : isCancelled
                  ? AppColors.textSecondary
                  : null,
            ),
          ),
          if (isProposed) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              value.proposedByCurrentUser
                  ? 'Esperando respuesta del otro propietario.'
                  : 'El otro propietario quiere considerar una posible camada.',
              style: AppTypography.bodySecondary,
            ),
          ],
          if (notes != null && notes.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(notes),
          ],
          if (expectedDate != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Fecha aproximada considerada: ${_date(expectedDate)}'),
          ],
          if (isAgreed && acceptedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Aceptada el ${_date(acceptedAt)}'),
          ],
          if (isCancelled && cancelledAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Cancelada el ${_date(cancelledAt)}'),
          ],
          const SizedBox(height: AppSpacing.md),
          if (isProposed && value.proposedByCurrentUser)
            AppButton(
              key: const Key('cancelBreedingIntent'),
              label: 'Cancelar propuesta',
              variant: AppButtonVariant.outlined,
              onPressed: () => _cancel(context, ref, value),
            )
          else if (isProposed)
            AppButton.primary(
              key: const Key('acceptBreedingIntent'),
              label: 'Aceptar propuesta',
              onPressed: () => _accept(context, ref, value),
            )
          else if (isAgreed)
            AppButton(
              key: const Key('cancelBreedingIntent'),
              label: 'Cancelar intención',
              variant: AppButtonVariant.outlined,
              onPressed: () => _cancel(context, ref, value),
            )
          else if (isCancelled)
            AppButton.primary(
              key: const Key('proposeBreedingIntent'),
              label: 'Proponer nueva intención',
              onPressed: () => _propose(context, ref),
            )
          else if (isCompleted)
            Text(
              'Esta intención quedó registrada como completada.',
              style: AppTypography.bodySecondary,
            ),
        ],
      ),
    );
  }

  Future<void> _propose(BuildContext context, WidgetRef ref) async {
    var notes = '';
    DateTime? expectedDate;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Proponer posible camada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas opcionales',
                ),
                onChanged: (value) => notes = value,
              ),
              TextButton.icon(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (selected != null) setState(() => expectedDate = selected);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  expectedDate == null
                      ? 'Fecha aproximada opcional'
                      : _date(expectedDate!),
                ),
              ),
              const Text(
                'Esto solo registra una intención. No confirma embarazo ni camada.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar propuesta'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(matchingControllerProvider.notifier)
        .proposeBreedingIntent(
          matchId,
          notes: notes,
          expectedDateUtc: expectedDate,
        );
    if (context.mounted) _feedback(context, result, 'Propuesta enviada.');
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    BreedingIntent value,
  ) async {
    final result = await ref
        .read(matchingControllerProvider.notifier)
        .acceptBreedingIntent(matchId, value.breedingIntentId);
    if (context.mounted) _feedback(context, result, 'Intención acordada.');
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    BreedingIntent value,
  ) async {
    final result = await ref
        .read(matchingControllerProvider.notifier)
        .cancelBreedingIntent(matchId, value.breedingIntentId);
    if (context.mounted) _feedback(context, result, 'Intención cancelada.');
  }
}

void _feedback<T>(BuildContext context, Result<T> result, String success) {
  result.when(
    success: (_) => AppSnackBar.showSuccess(context, success),
    failure: (failure) => AppSnackBar.showError(context, failure.message),
  );
}

String _date(DateTime value) =>
    '${value.day} ${_months[value.month - 1]} ${value.year}';

const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];
