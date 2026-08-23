import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/main_bottom_navigation.dart';
import '../../../pets/application/providers.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../application/providers.dart';
import '../../domain/entities/health.dart';
import 'vaccination_form_page.dart';

class HealthPage extends ConsumerStatefulWidget {
  const HealthPage({super.key});

  @override
  ConsumerState<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends ConsumerState<HealthPage> {
  String? _selectedPetId;

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(myPetsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Salud'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: pets.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(myPetsProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.pets_outlined,
                title: 'Aún no tienes mascotas',
                message: 'Registra una mascota para gestionar sus vacunas.',
              );
            }
            final selected = _selectedPet(items);
            return _HealthContent(
              key: ValueKey(selected.id),
              pets: items,
              selectedPet: selected,
              onPetChanged: (petId) => setState(() => _selectedPetId = petId),
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 2),
    );
  }

  PetSummary _selectedPet(List<PetSummary> pets) {
    final selectedId = _selectedPetId;
    if (selectedId == null) return pets.first;
    return pets.firstWhere(
      (pet) => pet.id == selectedId,
      orElse: () => pets.first,
    );
  }
}

class _HealthContent extends ConsumerStatefulWidget {
  const _HealthContent({
    super.key,
    required this.pets,
    required this.selectedPet,
    required this.onPetChanged,
  });

  final List<PetSummary> pets;
  final PetSummary selectedPet;
  final ValueChanged<String?> onPetChanged;

  @override
  ConsumerState<_HealthContent> createState() => _HealthContentState();
}

class _HealthContentState extends ConsumerState<_HealthContent> {
  bool _showAllAttention = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.selectedPet;
    final status = ref.watch(vaccinationStatusProvider(pet.id));
    final history = ref.watch(petVaccinationsProvider(pet.id));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: _PetSelector(
            pets: widget.pets,
            selectedPet: pet,
            onChanged: widget.onPetChanged,
          ),
        ),
        Expanded(
          child: status.when(
            loading: () => const AppLoadingIndicator(),
            error: (error, _) => ErrorState(
              message: error.toString(),
              onRetry: () => _invalidate(pet.id),
            ),
            data: (result) => history.when(
              loading: () => const AppLoadingIndicator(),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(petVaccinationsProvider(pet.id)),
              ),
              data: (records) => _VaccinationDashboard(
                petName: pet.name,
                result: result,
                records: records,
                showAllAttention: _showAllAttention,
                onToggleAttention: () =>
                    setState(() => _showAllAttention = !_showAllAttention),
                onRefresh: () async {
                  _invalidate(pet.id);
                  await ref.read(vaccinationStatusProvider(pet.id).future);
                },
                onRegister: (vaccination) =>
                    _openCreate(context, vaccineId: vaccination?.vaccineId),
                onEdit: (vaccination) => _openEdit(context, vaccination),
                onDelete: (vaccination) => _delete(context, vaccination),
              ),
            ),
          ),
        ),
        _BottomAction(onPressed: () => _openCreate(context)),
      ],
    );
  }

  void _invalidate(String petId) {
    ref.invalidate(vaccinationStatusProvider(petId));
    ref.invalidate(petVaccinationsProvider(petId));
  }

  Future<void> _openCreate(BuildContext context, {int? vaccineId}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => VaccinationFormPage(
          petId: widget.selectedPet.id,
          petName: widget.selectedPet.name,
          speciesId: widget.selectedPet.speciesId,
          initialVaccineId: vaccineId,
          lockVaccine: vaccineId != null,
        ),
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    PetVaccination vaccination,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => VaccinationFormPage(
          petId: widget.selectedPet.id,
          petName: widget.selectedPet.name,
          speciesId: widget.selectedPet.speciesId,
          vaccination: vaccination,
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, PetVaccination vaccination) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar registro',
      message: '¿Eliminar este registro de vacuna?',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(vaccinationMutationControllerProvider.notifier)
        .delete(widget.selectedPet.id, vaccination.petVaccinationId);
    if (!context.mounted) return;
    if (result.isFailure) {
      AppSnackBar.showError(context, result.failureOrNull!.message);
      return;
    }
    AppSnackBar.showSuccess(context, 'Registro de vacuna eliminado.');
  }
}

class _PetSelector extends StatelessWidget {
  const _PetSelector({
    required this.pets,
    required this.selectedPet,
    required this.onChanged,
  });

  final List<PetSummary> pets;
  final PetSummary selectedPet;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final age = selectedPet.ageYears;
    final subtitle = [
      selectedPet.speciesName,
      if (age != null) '$age ${age == 1 ? 'año' : 'años'}',
    ].join(' · ');
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        key: const Key('healthPetSelector'),
        borderRadius: AppRadius.lgAll,
        onTap: () => _choosePet(context),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            children: [
              AppNetworkImage(
                url: selectedPet.mainPhotoUrl,
                width: 48,
                height: 48,
                borderRadius: AppRadius.pillAll,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedPet.name, style: AppTypography.h3),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choosePet(BuildContext context) async {
    if (pets.length == 1) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text('Seleccionar mascota', style: AppTypography.h3),
            ),
            ...pets.map(
              (pet) => ListTile(
                leading: AppNetworkImage(
                  url: pet.mainPhotoUrl,
                  width: 40,
                  height: 40,
                  borderRadius: AppRadius.pillAll,
                ),
                title: Text(pet.name),
                subtitle: Text(pet.speciesName),
                trailing: pet.id == selectedPet.id
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, pet.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

class _VaccinationDashboard extends StatelessWidget {
  const _VaccinationDashboard({
    required this.petName,
    required this.result,
    required this.records,
    required this.showAllAttention,
    required this.onToggleAttention,
    required this.onRefresh,
    required this.onRegister,
    required this.onEdit,
    required this.onDelete,
  });

  final String petName;
  final VaccinationStatusResult result;
  final List<PetVaccination> records;
  final bool showAllAttention;
  final VoidCallback onToggleAttention;
  final Future<void> Function() onRefresh;
  final ValueChanged<PetVaccination?> onRegister;
  final ValueChanged<PetVaccination> onEdit;
  final ValueChanged<PetVaccination> onDelete;

  @override
  Widget build(BuildContext context) {
    final attention =
        result.vaccines.where(_requiresAttention).toList(growable: false)
          ..sort((a, b) => _priority(a.status).compareTo(_priority(b.status)));
    final upcoming =
        result.vaccines
            .where(
              (item) => item.status == 'NotStarted' && item.eligible == false,
            )
            .toList(growable: false)
          ..sort(_compareRecommendedDates);
    final upToDate = result.vaccines
        .where((item) => item.status == 'UpToDate')
        .toList(growable: false);
    final visibleAttention = showAllAttention
        ? attention
        : attention.take(3).toList(growable: false);
    final attentionCount =
        result.summary.notStarted +
        result.summary.overdue +
        result.summary.dueToday +
        result.summary.dueSoon;
    final upcomingKey = GlobalKey();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          if (attention.isNotEmpty) ...[
            _SectionHeader(
              title: 'Lo que necesita atención',
              count: attentionCount,
              actionLabel: attention.length > 3
                  ? (showAllAttention ? 'Ver menos' : 'Ver todo')
                  : null,
              onAction: onToggleAttention,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PriorityPanel(
              vaccines: visibleAttention,
              totalCount: attention.length,
              expanded: showAllAttention,
              records: records,
              onToggle: onToggleAttention,
              onRegister: onRegister,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ] else if (upcoming.isNotEmpty)
            _GrowingCard(
              petName: petName,
              firstVaccine: upcoming.first,
              onCalendar: () {
                final target = upcomingKey.currentContext;
                if (target != null) {
                  Scrollable.ensureVisible(
                    target,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              },
            )
          else
            const _AttentionEmpty(),
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Column(
              key: upcomingKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionHeader(title: 'Próximamente'),
                const SizedBox(height: AppSpacing.sm),
                ...upcoming.map(
                  (vaccination) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _UpcomingCard(vaccination: vaccination),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const _SectionHeader(title: 'Resumen de salud'),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(summary: result.summary),
          if (upToDate.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const _SectionHeader(title: 'Al día'),
            const SizedBox(height: AppSpacing.sm),
            ...upToDate.map(
              (vaccination) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _UpToDateCard(
                  vaccination: vaccination,
                  onEdit: () => onEdit(vaccination),
                  onDelete: () => onDelete(vaccination),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.count,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final int? count;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(child: Text(title, style: AppTypography.h3)),
      if (count != null) ...[
        const SizedBox(width: AppSpacing.sm),
        Container(
          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      const Spacer(),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class _PriorityPanel extends StatelessWidget {
  const _PriorityPanel({
    required this.vaccines,
    required this.totalCount,
    required this.expanded,
    required this.records,
    required this.onToggle,
    required this.onRegister,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PetVaccination> vaccines;
  final int totalCount;
  final bool expanded;
  final List<PetVaccination> records;
  final VoidCallback onToggle;
  final ValueChanged<PetVaccination?> onRegister;
  final ValueChanged<PetVaccination> onEdit;
  final ValueChanged<PetVaccination> onDelete;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      boxShadow: AppShadows.soft,
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        ...vaccines.map(
          (vaccination) => _PriorityCard(
            vaccination: vaccination,
            registered: records.any(
              (record) =>
                  record.petVaccinationId == vaccination.petVaccinationId,
            ),
            onRegister: () => onRegister(vaccination),
            onEdit: () => onEdit(vaccination),
            onDelete: () => onDelete(vaccination),
          ),
        ),
        if (totalCount > 3)
          TextButton(
            onPressed: onToggle,
            child: Text(
              expanded
                  ? 'Ver menos'
                  : 'Ver todas las $totalCount vacunas que requieren atención',
            ),
          ),
      ],
    ),
  );
}

class _GrowingCard extends StatelessWidget {
  const _GrowingCard({
    required this.petName,
    required this.firstVaccine,
    required this.onCalendar,
  });

  final String petName;
  final PetVaccination firstVaccine;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    final recommendedDate = firstVaccine.recommendedDueAtUtc;
    final eligibilityText = _eligibilityText(firstVaccine.daysUntilEligible);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$petName todavía está creciendo',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Su calendario de vacunas comenzará próximamente.',
                      style: AppTypography.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Primera vacuna recomendada', style: AppTypography.caption),
          const SizedBox(height: 2),
          Text(firstVaccine.vaccineName, style: AppTypography.h3),
          if (recommendedDate != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _friendlyDate(recommendedDate),
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          if (eligibilityText != null) ...[
            const SizedBox(height: 2),
            Text(eligibilityText, style: AppTypography.bodySecondary),
          ],
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onCalendar,
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: const Text('Ver calendario'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.vaccination});

  final PetVaccination vaccination;

  @override
  Widget build(BuildContext context) {
    final recommendedDate = vaccination.recommendedDueAtUtc;
    final eligibilityText = _eligibilityText(vaccination.daysUntilEligible);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VaccineIcon(color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        vaccination.vaccineName,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const _StatusBadge(
                      visual: _StatusVisual('Próximamente', AppColors.primary),
                    ),
                  ],
                ),
                if (recommendedDate != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Recomendada desde: ${_friendlyDate(recommendedDate)}',
                    style: AppTypography.caption,
                  ),
                ],
                if (eligibilityText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    eligibilityText,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.vaccination,
    required this.registered,
    required this.onRegister,
    required this.onEdit,
    required this.onDelete,
  });

  final PetVaccination vaccination;
  final bool registered;
  final VoidCallback onRegister;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(vaccination.status);
    final relevantDate = vaccination.status == 'NotStarted'
        ? vaccination.recommendedDueAtUtc
        : vaccination.nextDueAtUtc;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: visual.color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: visual.color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VaccineIcon(color: visual.color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        vaccination.vaccineName,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusBadge(visual: visual),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _statusMessage(vaccination.status),
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
                if (relevantDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_datePrefix(vaccination.status)}: '
                    '${_friendlyDate(relevantDate)}',
                    style: AppTypography.caption.copyWith(fontSize: 11),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      visualDensity: VisualDensity.compact,
                      textStyle: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: onRegister,
                    child: const Text('Registrar dosis'),
                  ),
                ),
              ],
            ),
          ),
          _CardActions(
            registered: registered,
            onRegister: onRegister,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.registered,
    required this.onRegister,
    required this.onEdit,
    required this.onDelete,
  });

  final bool registered;
  final VoidCallback onRegister;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (!registered) {
      return IconButton(
        visualDensity: VisualDensity.compact,
        onPressed: onRegister,
        icon: const Icon(Icons.chevron_right_rounded, size: 20),
      );
    }
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.chevron_right_rounded, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'register':
            onRegister();
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'register', child: Text('Registrar otra dosis')),
        PopupMenuItem(value: 'edit', child: Text('Editar registro')),
        PopupMenuItem(value: 'delete', child: Text('Eliminar registro')),
      ],
    );
  }
}

class _UpToDateCard extends StatelessWidget {
  const _UpToDateCard({
    required this.vaccination,
    required this.onEdit,
    required this.onDelete,
  });

  final PetVaccination vaccination;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.mdAll,
      border: Border.all(color: AppColors.success.withValues(alpha: 0.12)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vaccination.vaccineName, style: AppTypography.h3),
              if (vaccination.appliedAtUtc != null)
                Text(
                  'Última dosis: ${_friendlyDate(vaccination.appliedAtUtc!)}',
                  style: AppTypography.caption,
                ),
              if (vaccination.nextDueAtUtc != null)
                Text(
                  'Próxima: ${_friendlyDate(vaccination.nextDueAtUtc!)}',
                  style: AppTypography.caption,
                ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar registro')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar registro')),
          ],
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});
  final VaccinationSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('Al día', summary.upToDate, AppColors.success),
      _SummaryItem('Próximas', summary.dueSoon, AppColors.warning),
      _SummaryItem('Hoy', summary.dueToday, AppColors.warning),
      _SummaryItem('Vencidas', summary.overdue, AppColors.error),
    ];
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: item == items.last ? 0 : AppSpacing.xs,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.08),
                  borderRadius: AppRadius.smAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.count.toString(),
                      style: AppTypography.h2.copyWith(color: item.color),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(item.label, style: AppTypography.caption),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const Key('registerVaccinationButton'),
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Registrar una vacunación'),
      ),
    ),
  );
}

class _VaccineIcon extends StatelessWidget {
  const _VaccineIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.vaccines_outlined, color: color, size: 21),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.visual});
  final _StatusVisual visual;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: visual.color.withValues(alpha: 0.1),
      borderRadius: AppRadius.pillAll,
    ),
    child: Text(
      visual.label,
      style: AppTypography.caption.copyWith(
        color: visual.color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _AttentionEmpty extends StatelessWidget {
  const _AttentionEmpty();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.success.withValues(alpha: 0.07),
      borderRadius: AppRadius.lgAll,
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.success),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Todo bien por ahora. No hay vacunas que necesiten atención.',
            style: AppTypography.body,
          ),
        ),
      ],
    ),
  );
}

class _StatusVisual {
  const _StatusVisual(this.label, this.color);
  final String label;
  final Color color;
}

_StatusVisual _statusVisual(String status) => switch (status) {
  'UpToDate' => const _StatusVisual('Al día', AppColors.success),
  'DueSoon' => const _StatusVisual('Próxima', AppColors.warning),
  'DueToday' => const _StatusVisual('Hoy', AppColors.warning),
  'Overdue' => const _StatusVisual('Vencida', AppColors.error),
  'NotStarted' => const _StatusVisual('Sin registro', AppColors.error),
  _ => const _StatusVisual('Sin estado', AppColors.textSecondary),
};

bool _requiresAttention(PetVaccination vaccination) =>
    vaccination.status == 'Overdue' ||
    vaccination.status == 'DueToday' ||
    vaccination.status == 'DueSoon' ||
    (vaccination.status == 'NotStarted' && vaccination.eligible == true);

int _compareRecommendedDates(PetVaccination a, PetVaccination b) {
  final aDate = a.recommendedDueAtUtc;
  final bDate = b.recommendedDueAtUtc;
  if (aDate == null && bDate == null) return 0;
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  return aDate.compareTo(bDate);
}

String? _eligibilityText(int? days) {
  if (days == null || days <= 0) return null;
  return days == 1 ? 'Falta 1 día' : 'Faltan $days días';
}

int _priority(String status) => switch (status) {
  'NotStarted' => 0,
  'Overdue' => 1,
  'DueToday' => 2,
  'DueSoon' => 3,
  _ => 4,
};

String _statusMessage(String status) => switch (status) {
  'NotStarted' => 'No encontramos ninguna dosis registrada.',
  'Overdue' => 'Esta vacunación se encuentra vencida.',
  'DueToday' => 'La próxima dosis corresponde hoy.',
  'DueSoon' => 'La próxima dosis está cerca.',
  _ => 'La vacunación está al día.',
};

String _datePrefix(String status) => switch (status) {
  'NotStarted' => 'Recomendada desde',
  'Overdue' => 'Venció',
  _ => 'Próxima dosis',
};

String _friendlyDate(DateTime date) {
  const months = [
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
  final local = date.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
