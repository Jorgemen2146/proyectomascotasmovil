import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../pets/application/providers.dart';
import '../../application/providers.dart';
import '../../domain/entities/matching.dart';

class MatchingCandidatePage extends ConsumerStatefulWidget {
  const MatchingCandidatePage({
    super.key,
    required this.sourcePetId,
    required this.candidatePetId,
  });
  final String sourcePetId;
  final String candidatePetId;

  @override
  ConsumerState<MatchingCandidatePage> createState() =>
      _MatchingCandidatePageState();
}

class _MatchingCandidatePageState extends ConsumerState<MatchingCandidatePage> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final key = (
      sourcePetId: widget.sourcePetId,
      candidatePetId: widget.candidatePetId,
    );
    final detail = ref.watch(matchingCandidateProvider(key));
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de mascota')),
      body: detail.when(
        loading: () => const AppLoadingIndicator(),
        error: (_, _) => ErrorState(
          message: 'No pudimos cargar el perfil público.',
          onRetry: () => ref.invalidate(matchingCandidateProvider(key)),
        ),
        data: (candidate) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SizedBox(
              height: 260,
              child: PageView(
                children: [
                  for (final photo
                      in candidate.photoUrls.isEmpty
                          ? <String?>[candidate.mainPhotoUrl]
                          : candidate.photoUrls)
                    AppNetworkImage(
                      url: photo,
                      height: 260,
                      borderRadius: AppRadius.lgAll,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(candidate.name, style: AppTypography.h1),
            Text(
              '${candidate.breedName} · ${_sex(candidate.sex)} · ${_age(candidate.ageMonths)}',
              style: AppTypography.bodySecondary,
            ),
            if (candidate.color != null) Text('Color: ${candidate.color}'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                Chip(
                  label: Text('${candidate.compatibilityScore}% compatible'),
                ),
                if (candidate.pedigreeCompletenessPercentage != null)
                  const Chip(label: Text('Pedigree')),
              ],
            ),
            if (candidate.hasKnownRelationship) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: .12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️ Existe parentesco registrado'),
                    TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Detalle de parentesco'),
                          content: Text(
                            candidate.relationshipDescription ??
                                candidate.relationshipType ??
                                'El backend detectó una relación conocida.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Ver detalle'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('Acerca de ${candidate.name}', style: AppTypography.h3),
            Text(
              candidate.description ?? 'Sin descripción pública.',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Información del criador', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.sm),
                  const Row(
                    children: [
                      Icon(Icons.lock_outline),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Disponible después de que ambos acepten la solicitud.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(candidate.disclaimer, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.lg),
            if (_sent)
              const AppCard(
                child: ListTile(
                  leading: Icon(Icons.schedule, color: AppColors.primary),
                  title: Text('Solicitud enviada'),
                  subtitle: Text('Pendiente de respuesta'),
                ),
              )
            else
              AppButton.primary(
                key: const Key('sendMatchingRequest'),
                label: 'Enviar solicitud',
                isLoading: ref.watch(matchingControllerProvider),
                onPressed: () => _send(candidate),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(MatchingCandidate candidate) async {
    final myPet = await ref.read(petDetailsProvider(widget.sourcePetId).future);
    if (!mounted) return;
    var message = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Quieres enviar una solicitud para conocer a ${candidate.name}?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${myPet.name}  ↔  ${candidate.name}',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('matchingRequestMessage'),
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mensaje opcional'),
              onChanged: (value) => message = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(matchingControllerProvider.notifier)
        .sendRequest(
          petId: widget.sourcePetId,
          candidatePetId: widget.candidatePetId,
          message: message,
        );
    if (!mounted) return;
    result.when(
      success: (_) => setState(() => _sent = true),
      failure: (failure) => AppSnackBar.showError(context, failure.message),
    );
  }
}

String _age(int months) => months < 12
    ? '$months meses'
    : '${months ~/ 12} ${months ~/ 12 == 1 ? 'año' : 'años'}';
String _sex(String value) => value.toUpperCase() == 'F' ? 'Hembra' : 'Macho';
