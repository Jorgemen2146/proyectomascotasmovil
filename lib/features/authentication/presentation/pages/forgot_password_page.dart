import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_email_field.dart';
import '../../application/password_recovery_controller.dart';
import '../widgets/password_recovery_scaffold.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = ref.read(passwordRecoveryControllerProvider).email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(passwordRecoveryControllerProvider.notifier)
        .requestCode(_emailController.text);
    if (success && mounted) context.push(AppRoutes.verifyResetCode);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordRecoveryControllerProvider);
    return PasswordRecoveryScaffold(
      title: 'Recuperar contraseña',
      description:
          'Ingresa el correo asociado a tu cuenta y te enviaremos un código '
          'para restablecer tu contraseña.',
      icon: AppIcons.email,
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppEmailField(
              controller: _emailController,
              textInputAction: TextInputAction.done,
            ),
            if (state.error case final error?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(error, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              key: const Key('requestResetCode'),
              label: 'Enviar código',
              isLoading: state.requestingCode,
              onPressed: state.isBusy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
