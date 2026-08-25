import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_email_field.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../application/auth_state_controller.dart';
import '../../../legal/application/providers.dart';
import '../../../legal/domain/entities/legal.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final documents = ref.read(legalDocumentsProvider).valueOrNull;
    if (documents == null || !_hasRegistrationDocuments(documents)) {
      AppSnackBar.showError(
        context,
        'No pudimos cargar los términos y la política de privacidad.',
      );
      return;
    }
    if (!_acceptedTerms) {
      AppSnackBar.showError(
        context,
        'Debes aceptar los documentos requeridos.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(authStateControllerProvider.notifier)
        .register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          legalConsents: [
            for (final document in documents.where(
              (document) => document.requiresAcceptance,
            ))
              LegalConsentSelection(
                type: document.type,
                version: document.version,
              ),
          ],
          phoneNumber: null,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      final message = ref.read(authStateControllerProvider).errorMessage;
      AppSnackBar.showError(context, message ?? 'No se pudo crear la cuenta.');
      return;
    }

    context.go(AppRoutes.verifyEmail, extra: _emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final legalDocuments = ref.watch(legalDocumentsProvider);
    final documentsReady =
        legalDocuments.valueOrNull != null &&
        _hasRegistrationDocuments(legalDocuments.valueOrNull!);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FadeSlideIn(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crea tu cuenta',
                      style: AppTypography.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Únete a DogPlatform',
                      style: AppTypography.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Nombre',
                      controller: _firstNameController,
                      prefixIcon: AppIcons.person,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Apellido',
                      controller: _lastNameController,
                      prefixIcon: AppIcons.person,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppEmailField(controller: _emailController),
                    const SizedBox(height: AppSpacing.md),
                    AppPasswordField(controller: _passwordController),
                    const SizedBox(height: AppSpacing.md),
                    AppPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar contraseña',
                      textInputAction: TextInputAction.done,
                      autofillHints: const [],
                      validator: (value) => (value != _passwordController.text)
                          ? 'Las contraseñas no coinciden'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    legalDocuments.when(
                      loading: () => const _LegalLoading(),
                      error: (_, _) => _LegalLoadError(
                        onRetry: () => ref.invalidate(legalDocumentsProvider),
                      ),
                      data: (documents) => _TermsCheckbox(
                        value: _acceptedTerms,
                        onChanged: (value) =>
                            setState(() => _acceptedTerms = value),
                        onTermsTap: () => context.push(AppRoutes.legalTerms),
                        onPrivacyTap: () =>
                            context.push(AppRoutes.legalPrivacy),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.secondary(
                      label: 'Crear cuenta',
                      isLoading: _isSubmitting,
                      onPressed: documentsReady && _acceptedTerms
                          ? _submit
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'He leído y acepto los Términos y Condiciones y la Política de Privacidad',
      checked: value,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'He leído y acepto:',
                    style: AppTypography.bodySecondary,
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        key: const Key('registerTermsLink'),
                        onPressed: onTermsTap,
                        child: const Text('Términos y Condiciones'),
                      ),
                      Text('y la', style: AppTypography.bodySecondary),
                      TextButton(
                        key: const Key('registerPrivacyLink'),
                        onPressed: onPrivacyTap,
                        child: const Text('Política de Privacidad'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLoading extends StatelessWidget {
  const _LegalLoading();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      SizedBox(width: AppSpacing.sm),
      Expanded(child: Text('Cargando documentos legales…')),
    ],
  );
}

class _LegalLoadError extends StatelessWidget {
  const _LegalLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('No pudimos cargar los términos y la política de privacidad.'),
      TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    ],
  );
}

bool _hasRegistrationDocuments(List<LegalDocument> documents) =>
    documents.byType('TermsAndConditions') != null &&
    documents.byType('PrivacyPolicy') != null;
