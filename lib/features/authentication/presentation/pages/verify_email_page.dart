import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../application/verification_controller.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final success = await ref
        .read(verificationControllerProvider(widget.email).notifier)
        .verify(_codeController.text);
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(context, 'Correo verificado correctamente');
      context.go(AppRoutes.login);
      return;
    }
    final message = ref
        .read(verificationControllerProvider(widget.email))
        .errorMessage;
    if (message != null) AppSnackBar.showError(context, message);
  }

  Future<void> _resend() async {
    final success = await ref
        .read(verificationControllerProvider(widget.email).notifier)
        .resend();
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(
        context,
        'Si la cuenta existe, recibirás un nuevo código.',
      );
      return;
    }
    final message = ref
        .read(verificationControllerProvider(widget.email))
        .errorMessage;
    if (message != null) AppSnackBar.showError(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationControllerProvider(widget.email));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: FadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Verifica tu correo',
                    style: AppTypography.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Enviamos un código de 6 dígitos a\n${widget.email}',
                    style: AppTypography.bodySecondary,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _VerificationCodeInput(controller: _codeController),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton.primary(
                    label: 'Verificar',
                    isLoading: state.isVerifying,
                    onPressed: state.isResending ? null : _verify,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: const Key('resendButton'),
                    label: state.cooldownSeconds > 0
                        ? 'Reenviar código (${state.cooldownSeconds}s)'
                        : 'Reenviar código',
                    variant: AppButtonVariant.text,
                    isLoading: state.isResending,
                    onPressed: state.canResend ? _resend : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Volver a iniciar sesión',
                    variant: AppButtonVariant.text,
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationCodeInput extends StatefulWidget {
  const _VerificationCodeInput({required this.controller});

  final TextEditingController controller;

  @override
  State<_VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<_VerificationCodeInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    return Semantics(
      label: 'Código de verificación de 6 dígitos',
      textField: true,
      child: GestureDetector(
        onTap: _focusNode.requestFocus,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final digit = index < code.length ? code[index] : '';
                return Container(
                  width: 44,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Text(digit, style: AppTypography.h2),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  key: const Key('verificationCodeField'),
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onSubmitted: (_) => _verifyFromContext(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _verifyFromContext() {
    FocusScope.of(context).unfocus();
  }
}
