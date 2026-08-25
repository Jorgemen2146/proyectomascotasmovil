import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/providers.dart';
import '../../domain/entities/legal.dart';

class LegalDocumentPage extends ConsumerWidget {
  const LegalDocumentPage({super.key, required this.documentType});

  final String documentType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(legalDocumentsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_fallbackTitle(documentType))),
      body: SafeArea(
        child: documents.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => ErrorState(
            message: error is AppFailure
                ? error.message
                : 'No pudimos cargar el documento.',
            onRetry: () => ref.invalidate(legalDocumentsProvider),
          ),
          data: (items) {
            final document = items.byType(documentType);
            if (document == null) {
              return ErrorState(
                message: 'No pudimos cargar el documento.',
                onRetry: () => ref.invalidate(legalDocumentsProvider),
              );
            }
            return SelectionArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(document.title, style: AppTypography.h1),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Metadata(label: 'Versión ${document.version}'),
                      _Metadata(
                        label:
                            'Última actualización: ${_date(document.publishedAtUtc)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: SelectableText(
                      document.content,
                      style: AppTypography.body.copyWith(height: 1.65),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: AppColors.primary),
      ),
    ),
  );
}

String _fallbackTitle(String type) => type == 'PrivacyPolicy'
    ? 'Política de Privacidad'
    : 'Términos y Condiciones';

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
