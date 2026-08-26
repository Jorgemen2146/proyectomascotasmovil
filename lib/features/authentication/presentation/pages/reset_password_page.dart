import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../application/password_recovery_controller.dart';
import '../widgets/password_recovery_scaffold.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(passwordRecoveryControllerProvider.notifier)
        .resetPassword(
          newPassword: _passwordController.text,
          confirmPassword: _confirmationController.text,
        );
    _passwordController.clear();
    _confirmationController.clear();
    if (success && mounted) context.go(AppRoutes.passwordResetSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordRecoveryControllerProvider);
    return PasswordRecoveryScaffold(
      title: 'Nueva contraseña',
      description: 'Crea una contraseña segura para proteger tu cuenta.',
      icon: Icons.lock_reset_outlined,
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPasswordField(
              controller: _passwordController,
              label: 'Nueva contraseña',
              autofillHints: const [],
              validator: validateDogPlatformPassword,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Mínimo 6 caracteres.', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.md),
            AppPasswordField(
              controller: _confirmationController,
              label: 'Confirmar contraseña',
              textInputAction: TextInputAction.done,
              autofillHints: const [],
              validator: (value) => value == _passwordController.text
                  ? null
                  : 'Las contraseñas no coinciden',
            ),
            if (state.error case final error?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(error, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              key: const Key('resetPassword'),
              label: 'Restablecer contraseña',
              isLoading: state.resettingPassword,
              onPressed: state.isBusy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
