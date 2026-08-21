import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_email_field.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../application/auth_state_controller.dart';

const _loginPetsAsset = 'assets/images/01_dog_cat_login.png';
const _chatHeartAsset = 'assets/images/05_chat_heart_icon.png';
const _largePawAsset = 'assets/images/07_decorative_paw_large.png';
const _smallPawAsset = 'assets/images/08_decorative_paw_small.png';
const _securityShieldAsset = 'assets/images/09_security_shield.png';

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
    final email = _emailController.text.trim();
    final outcome = await ref
        .read(authStateControllerProvider.notifier)
        .login(email: email, password: _passwordController.text);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (outcome == LoginOutcome.emailNotVerified) {
      context.go(AppRoutes.verifyEmail, extra: email);
      return;
    }
    if (outcome == LoginOutcome.failure) {
      final message = ref.read(authStateControllerProvider).errorMessage;
      AppSnackBar.showError(context, message ?? 'No se pudo iniciar sesión.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
              final needsScroll = keyboardOpen || constraints.maxHeight < 820;
              final content = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: FadeSlideIn(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LoginHeader(),
                          Transform.translate(
                            offset: const Offset(0, -26),
                            child: _LoginForm(
                              emailController: _emailController,
                              passwordController: _passwordController,
                              isSubmitting: _isSubmitting,
                              onSubmit: _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              if (!needsScroll) {
                return Align(alignment: Alignment.topCenter, child: content);
              }
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FD)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 43,
            right: 25,
            child: Hero(
              tag: 'app-logo',
              child: Image.asset(_chatHeartAsset, width: 58, height: 58),
            ),
          ),
          Positioned(
            top: 61,
            left: 28,
            child: RichText(
              text: TextSpan(
                style: AppTypography.h1.copyWith(fontSize: 30, height: 1.24),
                children: const [
                  TextSpan(text: '¡Bienvenido de\n'),
                  TextSpan(
                    text: 'nuevo!',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  TextSpan(text: ' 👋'),
                ],
              ),
            ),
          ),
          Positioned(
            top: 153,
            left: 28,
            child: Text(
              'Inicia sesión para continuar',
              style: AppTypography.bodySecondary.copyWith(fontSize: 14),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 18,
            child: Image.asset(_largePawAsset, width: 61, height: 56),
          ),
          Positioned(
            left: 125,
            bottom: 53,
            child: Image.asset(_smallPawAsset, width: 40, height: 37),
          ),
          Positioned(
            right: -9,
            bottom: -5,
            child: Container(
              width: 170,
              height: 170,
              decoration: const BoxDecoration(
                color: Color(0xFFDDEBFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: 6,
            width: 193,
            height: 181,
            child: Image.asset(
              _loginPetsAsset,
              alignment: Alignment.bottomCenter,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 27, 24, 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppEmailField(controller: emailController),
          const SizedBox(height: 14),
          AppPasswordField(
            controller: passwordController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  AppSnackBar.showInfo(context, 'Próximamente disponible.'),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 15),
          _LoginButton(
            label: 'Iniciar sesión',
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'o continúa con',
                  style: AppTypography.bodySecondary.copyWith(fontSize: 13),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 15),
          const _SocialLoginRow(),
          const SizedBox(height: 21),
          const _SecurityNotice(),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('¿No tienes cuenta? ', style: AppTypography.bodySecondary),
              TextButton(
                onPressed: () => context.push(AppRoutes.register),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Crear cuenta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLoading ? 0.72 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2F6BFF), Color(0xFF284FEA)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  else
                    Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!isLoading)
                    const Positioned(
                      right: 18,
                      child: Icon(AppIcons.pets, color: Colors.white, size: 25),
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

class _SocialLoginRow extends StatelessWidget {
  const _SocialLoginRow();

  @override
  Widget build(BuildContext context) {
    void showComingSoon() {
      AppSnackBar.showInfo(context, 'Próximamente disponible.');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          onTap: showComingSoon,
          child: const SizedBox(
            width: 29,
            height: 29,
            child: CustomPaint(painter: _GoogleMarkPainter()),
          ),
        ),
        const SizedBox(width: 38),
        _SocialButton(
          onTap: showComingSoon,
          child: const Icon(Icons.apple_rounded, size: 27),
        ),
        const SizedBox(width: 38),
        _SocialButton(
          onTap: showComingSoon,
          child: const Icon(
            Icons.facebook_rounded,
            size: 29,
            color: Color(0xFF2F66E9),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 64, height: 64, child: Center(child: child)),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(3.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.butt;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -2.35, 1.48, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.45, 0.78, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 1.18, 1.30, false, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.15, 1.38, false, paint);
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.51),
      Offset(size.width * 0.91, size.height * 0.51),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.80, size.height * 0.51),
      Offset(size.width * 0.80, size.height * 0.72),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(9),
            child: Image.asset(_securityShieldAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu información está segura',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Usamos encriptación de nivel bancario',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
