import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/profile_controller.dart';

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
                const CircleAvatar(
                  radius: 44,
                  child: Icon(Icons.person, size: 48),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _nullable(_phoneController.text),
        );
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(context, 'Perfil actualizado correctamente.');
      context.pop();
    } else {
      final error = ref.read(profileControllerProvider).error;
      AppSnackBar.showError(
        context,
        error?.toString() ?? 'No se pudo guardar.',
      );
    }
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
