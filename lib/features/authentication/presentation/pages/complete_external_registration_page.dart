import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_email_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../application/auth_state_controller.dart';
import '../../domain/entities/external_auth.dart';
import '../../../legal/application/legal_data_providers.dart';
import '../../../legal/domain/entities/legal.dart';

class CompleteExternalRegistrationPage extends ConsumerStatefulWidget {
  const CompleteExternalRegistrationPage({
    required this.registration,
    super.key,
  });

  final ExternalRegistrationRequired registration;

  @override
  ConsumerState<CompleteExternalRegistrationPage> createState() =>
      _CompleteExternalRegistrationPageState();
}

class _CompleteExternalRegistrationPageState
    extends ConsumerState<CompleteExternalRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  bool _loading = false;
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.registration.email ?? '');
    _firstName = TextEditingController(
      text: widget.registration.firstName ?? '',
    );
    _lastName = TextEditingController(text: widget.registration.lastName ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final documents = ref.read(legalDocumentsProvider).valueOrNull;
    if (documents == null ||
        !documents.any((document) => document.requiresAcceptance)) {
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
    setState(() => _loading = true);
    final success = await ref
        .read(authStateControllerProvider.notifier)
        .completeExternalRegistration(
          registration: widget.registration,
          email: _email.text.trim(),
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          legalConsents: [
            for (final document in documents.where(
              (document) => document.requiresAcceptance,
            ))
              LegalConsentSelection(
                type: document.type,
                version: document.version,
              ),
          ],
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!success) {
      AppSnackBar.showError(
        context,
        ref.read(authStateControllerProvider).errorMessage ??
            'No se pudo completar el registro.',
      );
    }
  }

  bool _isMissing(String field) =>
      widget.registration.missingFields.contains(field);

  @override
  Widget build(BuildContext context) {
    final legalDocuments = ref.watch(legalDocumentsProvider);
    final documentsReady =
        legalDocuments.valueOrNull?.any(
          (document) => document.requiresAcceptance,
        ) ??
        false;
    return Scaffold(
      appBar: AppBar(title: const Text('Completa tu cuenta')),
      body: SafeArea(
        child: ResponsiveCenter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Sólo falta un paso', style: AppTypography.h1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Completa los datos que el proveedor no compartió.',
                    style: AppTypography.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_isMissing('firstName')) ...[
                    AppTextField(
                      label: 'Nombre',
                      controller: _firstName,
                      prefixIcon: AppIcons.person,
                      validator: _required,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_isMissing('lastName')) ...[
                    AppTextField(
                      label: 'Apellido',
                      controller: _lastName,
                      prefixIcon: AppIcons.person,
                      validator: _required,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_isMissing('email')) ...[
                    AppEmailField(controller: _email),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  legalDocuments.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'No pudimos cargar los documentos legales.',
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(legalDocumentsProvider),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                    data: (_) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _acceptedTerms,
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                      title: const Text(
                        'He leído y acepto los Términos y Condiciones y la Política de Privacidad.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.secondary(
                    label: 'Completar registro',
                    isLoading: _loading,
                    onPressed: !_loading && documentsReady && _acceptedTerms
                        ? _submit
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Requerido' : null;
}
