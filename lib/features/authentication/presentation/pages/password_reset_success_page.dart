import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/password_recovery_controller.dart';
import '../widgets/password_recovery_scaffold.dart';

class PasswordResetSuccessPage extends ConsumerWidget {
  const PasswordResetSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PasswordRecoveryScaffold(
      title: 'Contraseña actualizada',
      description:
          'Tu contraseña se cambió correctamente. Ya puedes iniciar sesión.',
      icon: Icons.check_circle_outline,
      child: AppButton.primary(
        key: const Key('passwordResetLogin'),
        label: 'Iniciar sesión',
        onPressed: () {
          ref.read(passwordRecoveryControllerProvider.notifier).clear();
          context.go(AppRoutes.login);
        },
      ),
    );
  }
}
