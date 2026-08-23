import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers.dart';
import '../../domain/entities/health.dart';

class VaccinationFormPage extends ConsumerStatefulWidget {
  const VaccinationFormPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.speciesId,
    this.initialVaccineId,
    this.lockVaccine = false,
    this.vaccination,
  });

  final String petId;
  final String petName;
  final int speciesId;
  final int? initialVaccineId;
  final bool lockVaccine;
  final PetVaccination? vaccination;

  bool get isEditing => vaccination != null;

  @override
  ConsumerState<VaccinationFormPage> createState() =>
      _VaccinationFormPageState();
}

class _VaccinationFormPageState extends ConsumerState<VaccinationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _doseController = TextEditingController();
  final _dateController = TextEditingController();
  final _veterinarianController = TextEditingController();
  final _clinicController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();
  int? _vaccineId;
  DateTime? _appliedAtUtc;

  @override
  void initState() {
    super.initState();
    _vaccineId = widget.initialVaccineId;
    final vaccination = widget.vaccination;
    if (vaccination != null) {
      _vaccineId = vaccination.vaccineId;
      _doseController.text = vaccination.doseNumber?.toString() ?? '';
      _appliedAtUtc = vaccination.appliedAtUtc;
      _dateController.text = _formatDate(vaccination.appliedAtUtc);
      _veterinarianController.text = vaccination.veterinarianName ?? '';
      _clinicController.text = vaccination.clinicName ?? '';
      _batchController.text = vaccination.batchNumber ?? '';
      _notesController.text = vaccination.notes ?? '';
    }
  }

  @override
  void dispose() {
    _doseController.dispose();
    _dateController.dispose();
    _veterinarianController.dispose();
    _clinicController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaccines = ref.watch(vaccinesBySpeciesProvider(widget.speciesId));
    final isSubmitting = ref.watch(vaccinationMutationControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar vacuna' : 'Registrar vacuna'),
      ),
      body: SafeArea(
        child: vaccines.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (items) => Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Vacunación', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Mascota'),
                    child: Text(widget.petName),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (widget.isEditing)
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Vacuna'),
                      child: Text(widget.vaccination!.vaccineName),
                    )
                  else if (widget.lockVaccine)
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Vacuna'),
                      child: Text(_selectedVaccineName(items)),
                    )
                  else
                    DropdownButtonFormField<int>(
                      key: const Key('vaccineField'),
                      initialValue: _vaccineId,
                      decoration: const InputDecoration(labelText: 'Vacuna *'),
                      items: items
                          .map(
                            (vaccine) => DropdownMenuItem(
                              value: vaccine.vaccineId,
                              child: Text(vaccine.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _vaccineId = value),
                      validator: (value) => value == null
                          ? 'Selecciona una vacuna del catálogo.'
                          : null,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('appliedAtField'),
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de aplicación *',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    validator: (_) => _appliedAtUtc == null
                        ? 'Selecciona la fecha de aplicación.'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const Key('doseNumberField'),
                    controller: _doseController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de dosis',
                      hintText: 'Ej. 1',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final dose = int.tryParse(value);
                      return dose == null || dose <= 0
                          ? 'Ingresa un número de dosis válido.'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Datos opcionales', style: AppTypography.h3),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _veterinarianController,
                    decoration: const InputDecoration(labelText: 'Veterinario'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _clinicController,
                    decoration: const InputDecoration(labelText: 'Clínica'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _batchController,
                    decoration: const InputDecoration(labelText: 'Lote'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton.primary(
                    label: widget.isEditing
                        ? 'Guardar cambios'
                        : 'Guardar vacuna',
                    isLoading: isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final current = _appliedAtUtc?.toLocal() ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current.isAfter(DateTime.now()) ? DateTime.now() : current,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (selected == null) return;
    setState(() {
      _appliedAtUtc = DateTime.utc(
        selected.year,
        selected.month,
        selected.day,
        12,
      );
      _dateController.text = _formatDate(selected);
    });
  }

  String _selectedVaccineName(List<Vaccine> vaccines) {
    for (final vaccine in vaccines) {
      if (vaccine.vaccineId == _vaccineId) return vaccine.name;
    }
    return 'Vacuna seleccionada';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final draft = VaccinationDraft(
      vaccineId: widget.isEditing ? null : _vaccineId,
      doseNumber: _doseController.text.trim().isEmpty
          ? null
          : int.parse(_doseController.text),
      appliedAtUtc: _appliedAtUtc!,
      veterinarianName: _nullable(_veterinarianController.text),
      clinicName: _nullable(_clinicController.text),
      batchNumber: _nullable(_batchController.text),
      notes: _nullable(_notesController.text),
    );
    final controller = ref.read(vaccinationMutationControllerProvider.notifier);
    final result = widget.isEditing
        ? await controller.update(
            widget.petId,
            widget.vaccination!.petVaccinationId,
            draft,
          )
        : await controller.create(widget.petId, draft);
    if (!mounted) return;
    if (result.isFailure) {
      AppSnackBar.showError(context, result.failureOrNull!.message);
      return;
    }
    AppSnackBar.showSuccess(
      context,
      widget.isEditing
          ? 'Vacuna actualizada correctamente.'
          : 'Vacuna registrada correctamente.',
    );
    context.pop();
  }
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
