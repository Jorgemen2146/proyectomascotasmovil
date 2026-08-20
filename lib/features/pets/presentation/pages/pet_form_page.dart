import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers.dart';
import '../../domain/entities/pet.dart';

class PetFormPage extends ConsumerStatefulWidget {
  const PetFormPage({super.key, this.petId});

  final String? petId;
  bool get isEditing => petId != null;

  @override
  ConsumerState<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends ConsumerState<PetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _colorController = TextEditingController();
  final _pedigreeController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _speciesId;
  int? _breedId;
  DateTime? _birthDate;
  String _gender = 'M';
  bool _isSterilized = false;
  SelectedPhoto? _selectedPhoto;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _colorController.dispose();
    _pedigreeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final details = ref.watch(petDetailsProvider(widget.petId!));
      return details.when(
        loading: () => const Scaffold(body: AppLoadingIndicator()),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Editar mascota')),
          body: Center(child: Text(error.toString())),
        ),
        data: (pet) {
          _initializeFrom(pet);
          return _buildScaffold();
        },
      );
    }
    return _buildScaffold();
  }

  Widget _buildScaffold() {
    final isSubmitting = ref.watch(petFormControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar mascota' : 'Agregar mascota'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.isEditing) ...[
                  _PhotoSelector(
                    photo: _selectedPhoto,
                    onTap: _showPhotoSource,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text('Información básica', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('petNameField'),
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre.'
                      : null,
                ),
                if (!widget.isEditing) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SpeciesField(
                    value: _speciesId,
                    onChanged: (value) => setState(() {
                      _speciesId = value;
                      _breedId = null;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BreedField(
                    speciesId: _speciesId,
                    value: _breedId,
                    onChanged: (value) => setState(() => _breedId = value),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('birthDateField'),
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _pickBirthDate,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Datos adicionales', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.md),
                Text('Sexo', style: AppTypography.bodySecondary),
                const SizedBox(height: AppSpacing.xs),
                SegmentedButton<String>(
                  key: const Key('genderSelector'),
                  segments: const [
                    ButtonSegment(value: 'M', label: Text('Macho')),
                    ButtonSegment(value: 'F', label: Text('Hembra')),
                  ],
                  selected: {_gender},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _gender = value.first),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('petWeightField'),
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final weight = double.tryParse(value.replaceAll(',', '.'));
                    return weight == null || weight <= 0
                        ? 'Ingresa un peso válido.'
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(labelText: 'Color'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _pedigreeController,
                  decoration: const InputDecoration(
                    labelText: 'Pedigree (opcional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Esterilizado'),
                  value: _isSterilized,
                  onChanged: (value) => setState(() => _isSterilized = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: 'Guardar',
                  isLoading: isSubmitting,
                  onPressed: _submit,
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Eliminar mascota',
                    variant: AppButtonVariant.outlined,
                    onPressed: _delete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _initializeFrom(PetDetails pet) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = pet.name;
    _birthDate = pet.birthDate;
    _birthDateController.text = _formatDate(pet.birthDate);
    _gender = pet.gender;
    _weightController.text = pet.weight?.toString() ?? '';
    _colorController.text = pet.color ?? '';
    _pedigreeController.text = pet.pedigreeNumber ?? '';
    _isSterilized = pet.isSterilized;
    _descriptionController.text = pet.description ?? '';
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    setState(() {
      _birthDate = date;
      _birthDateController.text = _formatDate(date);
    });
  }

  Future<void> _showPhotoSource() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, PhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, PhotoSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final result = await ref.read(photoPickerServiceProvider).pick(source);
    if (!mounted) return;
    switch (result) {
      case PhotoSelected(:final photo):
        setState(() => _selectedPhoto = photo);
      case PhotoSelectionInvalid(:final message):
        AppSnackBar.showError(context, message);
      case PhotoSelectionCancelled():
        break;
    }
  }

  PetDraft _draft() => PetDraft(
    breedId: _breedId,
    name: _nameController.text.trim(),
    birthDate: _birthDate,
    gender: _gender,
    weight: _weightController.text.trim().isEmpty
        ? null
        : double.parse(_weightController.text.replaceAll(',', '.')),
    color: _nullable(_colorController.text),
    pedigreeNumber: _nullable(_pedigreeController.text),
    isSterilized: _isSterilized,
    description: _nullable(_descriptionController.text),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!widget.isEditing && (_speciesId == null || _breedId == null)) {
      AppSnackBar.showError(context, 'Selecciona una especie y una raza.');
      return;
    }

    final controller = ref.read(petFormControllerProvider.notifier);
    if (widget.isEditing) {
      final result = await controller.update(widget.petId!, _draft());
      if (!mounted) return;
      if (result.isFailure) {
        AppSnackBar.showError(context, result.failureOrNull!.message);
        return;
      }
      AppSnackBar.showSuccess(context, 'Mascota actualizada correctamente.');
      context.pop();
      return;
    }

    final result = await controller.create(_draft());
    if (!mounted) return;
    if (result.isFailure) {
      AppSnackBar.showError(context, result.failureOrNull!.message);
      return;
    }
    final petId = result.valueOrNull!;
    final photo = _selectedPhoto;
    if (photo != null) {
      final photoResult = await ref
          .read(petPhotoControllerProvider.notifier)
          .upload(petId, photo);
      if (!mounted) return;
      if (photoResult.isFailure) {
        AppSnackBar.showError(
          context,
          'La mascota fue creada, pero no se pudo subir la foto.',
        );
      }
    }
    if (!mounted) return;
    context.go(AppRoutes.petDetails(petId));
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar mascota',
      message: 'Esta acción eliminará la mascota de tu cuenta.',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(petFormControllerProvider.notifier)
        .delete(widget.petId!);
    if (!mounted) return;
    if (result.isFailure) {
      AppSnackBar.showError(context, result.failureOrNull!.message);
      return;
    }
    context.go(AppRoutes.pets);
  }
}

class _SpeciesField extends ConsumerWidget {
  const _SpeciesField({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final species = ref.watch(speciesProvider);
    return species.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('No se pudieron cargar especies: $error'),
      data: (items) => DropdownButtonFormField<int>(
        key: const Key('speciesField'),
        initialValue: value,
        decoration: const InputDecoration(labelText: 'Especie *'),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item.speciesId,
                child: Text(item.name),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _BreedField extends ConsumerWidget {
  const _BreedField({
    required this.speciesId,
    required this.value,
    required this.onChanged,
  });
  final int? speciesId;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (speciesId == null) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Raza *'),
        child: Text('Selecciona primero una especie'),
      );
    }
    final breeds = ref.watch(breedsProvider(speciesId!));
    return breeds.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('No se pudieron cargar razas: $error'),
      data: (items) => DropdownButtonFormField<int>(
        key: const Key('breedField'),
        initialValue: value,
        decoration: const InputDecoration(labelText: 'Raza *'),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem(value: item.breedId, child: Text(item.name)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _PhotoSelector extends StatelessWidget {
  const _PhotoSelector({required this.photo, required this.onTap});
  final SelectedPhoto? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        key: const Key('photoSelector'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(64),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: photo == null
                  ? null
                  : FileImage(File(photo!.file.path)),
              child: photo == null
                  ? const Icon(
                      Icons.camera_alt_outlined,
                      size: 32,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Agregar foto', style: AppTypography.caption),
          ],
        ),
      ),
    );
  }
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
