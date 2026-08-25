import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../authentication/application/auth_state_controller.dart';
import '../../application/providers.dart';
import '../../domain/entities/legal.dart';

class LegalUpdatePage extends ConsumerStatefulWidget {
  const LegalUpdatePage({super.key});

  @override
  ConsumerState<LegalUpdatePage> createState() => _LegalUpdatePageState();
}

class _LegalUpdatePageState extends ConsumerState<LegalUpdatePage> {
  final acceptedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(legalStatusProvider);
    final submitting = ref.watch(legalControllerProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Actualización legal'),
        ),
        body: SafeArea(
          child: status.when(
            loading: () => const AppLoadingIndicator(),
            error: (error, _) => Column(
              children: [
                Expanded(
                  child: ErrorState(
                    title: 'No pudimos verificar tus consentimientos',
                    message: error is AppFailure
                        ? error.message
                        : 'Revisa tu conexión e inténtalo nuevamente.',
                    onRetry: () => ref.invalidate(legalStatusProvider),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(authStateControllerProvider.notifier).logout(),
                  child: const Text('Cerrar sesión'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
            data: (value) {
              if (value.isUpToDate || value.pendingDocuments.isEmpty) {
                return const Center(child: Text('Consentimientos al día.'));
              }
              final allAccepted = value.pendingDocuments.every(
                (document) => acceptedIds.contains(document.legalDocumentId),
              );
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const Icon(
                    Icons.policy_outlined,
                    size: 52,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Hemos actualizado nuestros documentos legales',
                    style: AppTypography.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Lee y acepta explícitamente cada nueva versión para continuar.',
                    style: AppTypography.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  for (final document in value.pendingDocuments) ...[
                    _PendingDocumentCard(
                      document: document,
                      accepted: acceptedIds.contains(document.legalDocumentId),
                      onChanged: (checked) => setState(() {
                        checked
                            ? acceptedIds.add(document.legalDocumentId)
                            : acceptedIds.remove(document.legalDocumentId);
                      }),
                      onRead: () => context.push(
                        document.type == 'PrivacyPolicy'
                            ? AppRoutes.legalPrivacy
                            : AppRoutes.legalTerms,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppButton.primary(
                    label: 'Aceptar y continuar',
                    isLoading: submitting,
                    onPressed: allAccepted
                        ? () => _acceptAll(value.pendingDocuments)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () =>
                        ref.read(authStateControllerProvider.notifier).logout(),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _acceptAll(List<LegalDocument> documents) async {
    for (final document in documents) {
      final result = await ref
          .read(legalControllerProvider.notifier)
          .acceptDocument(document.legalDocumentId);
      if (result.isFailure) {
        if (mounted) {
          AppSnackBar.showError(context, result.failureOrNull!.message);
        }
        return;
      }
    }
    ref.invalidate(legalStatusProvider);
    if (mounted) {
      AppSnackBar.showSuccess(context, 'Documentos legales aceptados.');
    }
  }
}

class _PendingDocumentCard extends StatelessWidget {
  const _PendingDocumentCard({
    required this.document,
    required this.accepted,
    required this.onChanged,
    required this.onRead,
  });

  final LegalDocument document;
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(document.title, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.xs),
        Text('Versión ${document.version}', style: AppTypography.bodySecondary),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onRead,
            child: const Text('Leer documento'),
          ),
        ),
        CheckboxListTile(
          key: Key('acceptLegal-${document.legalDocumentId}'),
          contentPadding: EdgeInsets.zero,
          value: accepted,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('He leído y acepto la nueva versión.'),
          onChanged: (value) => onChanged(value ?? false),
        ),
      ],
    ),
  );
}
