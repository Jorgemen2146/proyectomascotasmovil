import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/profile_controller.dart';
import '../widgets/profile_photo_source_sheet.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  SelectedPhoto? _selectedPhoto;
  bool _initialized = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: profile.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
        data: (user) {
          if (!_initialized) {
            _initialized = true;
            final parts = user.fullName.trim().split(RegExp(r'\s+'));
            _firstNameController.text = parts.firstOrNull ?? '';
            _lastNameController.text = parts.length > 1
                ? parts.skip(1).join(' ')
                : '';
            _emailController.text = user.email;
            _phoneController.text = user.phoneNumber ?? '';
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _EditableProfileAvatar(
                  selectedPhoto: _selectedPhoto,
                  currentPhotoUrl: user.profilePhotoUrl,
                  onTap: _showPhotoSource,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  key: const Key('profileFirstNameField'),
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('profileLastNameField'),
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Apellido *'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('profilePhoneField'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton.primary(label: 'Guardar', onPressed: _save),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPhotoSource() async {
    final source = await showProfilePhotoSourceSheet(context);
    if (source == null || !mounted) return;
    final result = await ref.read(profilePhotoPickerProvider).pick(source);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final outcome = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _nullable(_phoneController.text),
          photo: _selectedPhoto,
        );
    if (!mounted) return;
    if (outcome == null || outcome.refreshFailure != null) {
      final error = ref.read(profileControllerProvider).error;
      AppSnackBar.showError(
        context,
        error?.toString() ?? 'No se pudo guardar.',
      );
      return;
    }

    final photoFailure = outcome.photoFailure;
    if (photoFailure != null) {
      final errorId = photoFailure is ServerFailure
          ? photoFailure.errorCode
          : null;
      AppSnackBar.showError(
        context,
        errorId == null || errorId.isEmpty
            ? 'Tu perfil fue actualizado, pero no se pudo guardar la foto.'
            : 'No se pudo guardar la foto. Código: $errorId',
      );
    } else {
      AppSnackBar.showSuccess(context, 'Perfil actualizado correctamente.');
    }
    context.pop();
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({
    required this.selectedPhoto,
    required this.currentPhotoUrl,
    required this.onTap,
  });

  final SelectedPhoto? selectedPhoto;
  final String? currentPhotoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        key: const Key('profilePhotoSelector'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: SizedBox.square(
                dimension: 88,
                child: selectedPhoto != null
                    ? Image.file(
                        File(selectedPhoto!.file.path),
                        fit: BoxFit.cover,
                      )
                    : currentPhotoUrl != null
                    ? AppNetworkImage(url: currentPhotoUrl, fit: BoxFit.cover)
                    : const ColoredBox(
                        color: Color(0xFFDBEAFE),
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(Icons.camera_alt, size: 17, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Este campo es obligatorio.' : null;

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
