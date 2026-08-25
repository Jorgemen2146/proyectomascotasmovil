import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/providers.dart';
import '../../domain/entities/legal.dart';

class LegalHistoryPage extends ConsumerWidget {
  const LegalHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(legalConsentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de aceptaciones')),
      body: history.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorState(
          message: error is AppFailure
              ? error.message
              : 'No pudimos cargar tu historial.',
          onRetry: () => ref.invalidate(legalConsentsProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.history_outlined,
                title: 'Sin aceptaciones registradas',
                message: 'Tu historial legal aparecerá aquí.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, index) => _ConsentTile(items[index]),
              ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile(this.consent);

  final LegalConsentHistory consent;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const CircleAvatar(child: Icon(Icons.verified_outlined)),
    title: Text(_title(consent.type), style: AppTypography.h3),
    subtitle: Text(
      'Versión ${consent.version}\nAceptado: ${_date(consent.acceptedAtUtc)}',
    ),
    isThreeLine: true,
  );
}

String _title(String type) => type == 'PrivacyPolicy'
    ? 'Política de Privacidad'
    : 'Términos y Condiciones';

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
