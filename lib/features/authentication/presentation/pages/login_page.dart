import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../application/auth_state_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final success = await ref.read(authStateControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      final message = ref.read(authStateControllerProvider).errorMessage;
      AppSnackBar.showError(context, message ?? 'Login failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.pets, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) => (value == null || !value.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    autofillHints: const [AutofillHints.password],
                    validator: (value) => (value == null || value.length < 6)
                        ? 'Minimum 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Log in',
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Create an account',
                    variant: AppButtonVariant.text,
                    onPressed: () => context.push(AppRoutes.register),
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
