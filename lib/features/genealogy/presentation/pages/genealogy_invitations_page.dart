import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/gateway_url_resolver.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../pets/application/providers.dart';
import '../../application/providers.dart';
import '../../domain/entities/genealogy.dart';

class GenealogyInvitationsPage extends ConsumerWidget {
  const GenealogyInvitationsPage({super.key, this.invitationToken});

  final String? invitationToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes genealógicas'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Recibidas'),
            Tab(text: 'Enviadas'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (invitationToken case final token?)
            _InvitationActionCard(token: token),
          const Expanded(
            child: TabBarView(
              children: [
                _InvitationList(direction: 'incoming'),
                _InvitationList(direction: 'outgoing'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _InvitationList extends ConsumerWidget {
  const _InvitationList({required this.direction});

  final String direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (direction: direction, status: null as String?);
    final invitations = ref.watch(genealogyInvitationsProvider(query));
    return invitations.when(
      loading: () => const AppLoadingIndicator(),
      error: (error, _) => ErrorState(
        message: error is AppFailure
            ? error.message
            : 'No pudimos cargar las solicitudes.',
        onRetry: () => ref.invalidate(genealogyInvitationsProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.mail_outline,
            title: 'Sin solicitudes',
            message: 'No hay solicitudes en esta sección.',
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(genealogyInvitationsProvider(query).future),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, index) => _InvitationTile(
              invitation: items[index],
              outgoing: direction == 'outgoing',
            ),
          ),
        );
      },
    );
  }
}

class _InvitationTile extends ConsumerWidget {
  const _InvitationTile({required this.invitation, required this.outgoing});

  final GenealogyInvitation invitation;
  final bool outgoing;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: ListTile(
      key: Key('invitation-${invitation.invitationId}'),
      leading: const CircleAvatar(child: Icon(Icons.account_tree_outlined)),
      title: Text(invitation.childPetName),
      subtitle: Text(
        '${_role(invitation.parentRole)} · ${_status(invitation.status)}',
      ),
      trailing: outgoing && invitation.isPending
          ? TextButton(
              key: Key('cancelInvitation-${invitation.invitationId}'),
              onPressed: () async {
                final result = await ref
                    .read(genealogyControllerProvider.notifier)
                    .cancelInvitation(invitation.invitationId);
                if (!context.mounted) return;
                result.isSuccess
                    ? AppSnackBar.showSuccess(context, 'Invitación cancelada.')
                    : AppSnackBar.showError(
                        context,
                        result.failureOrNull!.message,
                      );
              },
              child: const Text('Cancelar'),
            )
          : null,
    ),
  );
}

class _InvitationActionCard extends ConsumerStatefulWidget {
  const _InvitationActionCard({required this.token});

  final String token;

  @override
  ConsumerState<_InvitationActionCard> createState() =>
      _InvitationActionCardState();
}

class _InvitationActionCardState extends ConsumerState<_InvitationActionCard> {
  String? petId;

  @override
  Widget build(BuildContext context) {
    final invitation = ref.watch(
      genealogyInvitationContextProvider(widget.token),
    );
    final pets = ref.watch(myPetsProvider);
    return invitation.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          error is AppFailure ? error.message : 'Invitación no disponible.',
        ),
      ),
      data: (item) => Container(
        color: AppColors.primary.withValues(alpha: .05),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Solicitud genealógica', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                ClipOval(
                  child: AppNetworkImage(
                    url: GatewayUrlResolver.resolve(item.childMainPhotoUrl),
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.childPetName,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${item.requesterDisplayName} quiere relacionar una de tus '
              'mascotas como ${_role(item.parentRole).toLowerCase()} de '
              '${item.childPetName}.',
            ),
            const SizedBox(height: AppSpacing.sm),
            pets.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('No pudimos cargar tus mascotas.'),
              data: (items) => DropdownButtonFormField<String>(
                key: const Key('invitationPetSelector'),
                initialValue: petId,
                decoration: const InputDecoration(
                  labelText: 'Selecciona tu mascota',
                ),
                items: [
                  for (final pet in items)
                    DropdownMenuItem(value: pet.id, child: Text(pet.name)),
                ],
                onChanged: (value) => setState(() => petId = value),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('rejectInvitation'),
                    onPressed: () => _reject(context),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('acceptInvitation'),
                    onPressed: petId == null ? null : () => _accept(context),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    final result = await ref
        .read(genealogyControllerProvider.notifier)
        .acceptInvitation(token: widget.token, petId: petId!);
    if (!context.mounted) return;
    result.isSuccess
        ? AppSnackBar.showSuccess(context, 'Invitación aceptada.')
        : AppSnackBar.showError(context, result.failureOrNull!.message);
  }

  Future<void> _reject(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: '¿Rechazar esta solicitud?',
      message: 'La relación genealógica no se creará.',
      confirmLabel: 'Rechazar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (!context.mounted || !confirmed) return;
    final result = await ref
        .read(genealogyControllerProvider.notifier)
        .rejectInvitation(widget.token);
    if (!context.mounted) return;
    result.isSuccess
        ? AppSnackBar.showSuccess(context, 'Invitación rechazada.')
        : AppSnackBar.showError(context, result.failureOrNull!.message);
  }
}

String _role(String value) =>
    value.toLowerCase() == 'father' ? 'Padre' : 'Madre';

String _status(String value) => switch (value.toLowerCase()) {
  'pending' => 'Pendiente',
  'accepted' => 'Aceptada',
  'rejected' => 'Rechazada',
  'cancelled' => 'Cancelada',
  'expired' => 'Expirada',
  _ => value,
};
