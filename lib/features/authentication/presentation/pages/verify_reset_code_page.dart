import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/password_recovery_controller.dart';
import '../widgets/password_recovery_scaffold.dart';

class VerifyResetCodePage extends ConsumerStatefulWidget {
  const VerifyResetCodePage({super.key, this.cooldownSeconds = 60});

  final int cooldownSeconds;

  @override
  ConsumerState<VerifyResetCodePage> createState() =>
      _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends ConsumerState<VerifyResetCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _timer;
  late int _secondsRemaining;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _secondsRemaining = widget.cooldownSeconds;
    if (_secondsRemaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(passwordRecoveryControllerProvider.notifier)
        .verifyCode(_codeController.text);
    if (success && mounted) context.push(AppRoutes.resetPassword);
  }

  Future<void> _resend() async {
    final success = await ref
        .read(passwordRecoveryControllerProvider.notifier)
        .resendCode();
    if (!mounted || !success) return;
    _codeController.clear();
    _startCooldown();
    setState(() {});
    AppSnackBar.showSuccess(context, 'Te enviamos un nuevo código.');
  }

  void _back() {
    ref.read(passwordRecoveryControllerProvider.notifier).returnToEmail();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordRecoveryControllerProvider);
    return PasswordRecoveryScaffold(
      title: 'Verifica tu correo',
      description:
          'Ingresa el código de 6 dígitos que enviamos a '
          '${maskRecoveryEmail(state.email)}.',
      icon: Icons.mark_email_read_outlined,
      onBack: _back,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('resetCodeField'),
              controller: _codeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 10,
              ),
              maxLength: 6,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'Código',
                counterText: '',
              ),
              validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                  ? null
                  : 'Ingresa el código de 6 dígitos.',
            ),
            if (state.error case final error?) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(error, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              key: const Key('verifyResetCode'),
              label: 'Verificar código',
              isLoading: state.verifyingCode,
              onPressed: state.isBusy ? null : _verify,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('¿No recibiste el código?', textAlign: TextAlign.center),
            TextButton(
              key: const Key('resendResetCode'),
              onPressed: _secondsRemaining == 0 && !state.isBusy
                  ? _resend
                  : null,
              child: Text(
                _secondsRemaining > 0
                    ? 'Reenviar código en $_secondsRemaining s'
                    : 'Reenviar código',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String maskRecoveryEmail(String email) {
  final separator = email.indexOf('@');
  if (separator <= 0) return email;
  final local = email.substring(0, separator);
  final visible = local.substring(0, local.length.clamp(1, 3).toInt());
  return '$visible***${email.substring(separator)}';
}
