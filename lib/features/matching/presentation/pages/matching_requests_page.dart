import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/result/result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/providers.dart';
import '../../domain/entities/matching.dart';

class MatchingRequestsPage extends ConsumerWidget {
  const MatchingRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Recibidas'),
            Tab(text: 'Enviadas'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _RequestsList(incoming: true),
          _RequestsList(incoming: false),
        ],
      ),
    ),
  );
}

class _RequestsList extends ConsumerWidget {
  const _RequestsList({required this.incoming});
  final bool incoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = incoming
        ? incomingRequestsProvider
        : outgoingRequestsProvider;
    final requests = ref.watch(provider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(provider),
      child: requests.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, _) => ErrorState(
          message: 'No pudimos cargar tus solicitudes.',
          onRetry: () => ref.invalidate(provider),
        ),
        data: (items) => items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 140),
                  EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No tienes solicitudes pendientes.',
                    message: 'Las nuevas solicitudes aparecerán aquí.',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, index) =>
                    _RequestCard(request: items[index], incoming: incoming),
              ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request, required this.incoming});
  final MatchRequest request;
  final bool incoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = incoming ? request.requesterPet : request.targetPet;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppNetworkImage(
                url: pet?.mainPhotoUrl,
                width: 64,
                height: 64,
                borderRadius: BorderRadius.circular(32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet?.name ?? 'Mascota', style: AppTypography.h3),
                    if (pet != null) Text(pet.breedName),
                    Text(
                      _date(request.createdAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(request.message!),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Chip(
              label: Text(_statusLabel(request.status)),
              backgroundColor: _statusColor(
                request.status,
              ).withValues(alpha: .10),
              labelStyle: AppTypography.small.copyWith(
                color: _statusColor(request.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (request.status == 'Pending' && incoming)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Rechazar',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _reject(context, ref),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton.primary(
                    label: 'Aceptar',
                    onPressed: () => _accept(context, ref),
                  ),
                ),
              ],
            )
          else if (request.status == 'Pending')
            AppButton(
              label: 'Cancelar solicitud',
              variant: AppButtonVariant.outlined,
              onPressed: () => _cancel(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    var sharePhone = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('¿Qué información deseas compartir?'),
          content: CheckboxListTile(
            key: const Key('shareMatchingPhone'),
            contentPadding: EdgeInsets.zero,
            value: sharePhone,
            title: const Text('Número de teléfono'),
            onChanged: (value) => setState(() => sharePhone = value ?? false),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aceptar solicitud'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !context.mounted) return;
    final result = await ref
        .read(matchingControllerProvider.notifier)
        .acceptRequest(request.matchRequestId, sharePhoneNumber: sharePhone);
    if (!context.mounted) return;
    _showResult(context, result, 'Solicitud aceptada.');
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '¿Rechazar esta solicitud?',
      message: 'La otra persona no recibirá información de contacto.',
      confirmLabel: 'Rechazar',
      cancelLabel: 'Volver',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(matchingControllerProvider.notifier)
        .rejectRequest(request.matchRequestId);
    if (context.mounted) _showResult(context, result, 'Solicitud rechazada.');
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Cancelar solicitud',
      message: '¿Quieres cancelar esta solicitud pendiente?',
      confirmLabel: 'Cancelar solicitud',
      cancelLabel: 'Volver',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(matchingControllerProvider.notifier)
        .cancelRequest(request.matchRequestId);
    if (context.mounted) _showResult(context, result, 'Solicitud cancelada.');
  }
}

void _showResult<T>(BuildContext context, Result<T> result, String success) {
  result.when(
    success: (_) => AppSnackBar.showSuccess(context, success),
    failure: (failure) => AppSnackBar.showError(context, failure.message),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _statusLabel(String status) => switch (status) {
  'Pending' => 'Pendiente',
  'Accepted' => 'Aceptada',
  'Rejected' => 'Rechazada',
  'Cancelled' => 'Cancelada',
  'Expired' => 'Vencida',
  _ => status,
};

Color _statusColor(String status) => switch (status) {
  'Accepted' => AppColors.success,
  'Rejected' => AppColors.error,
  'Cancelled' || 'Expired' => AppColors.textSecondary,
  _ => AppColors.primary,
};
