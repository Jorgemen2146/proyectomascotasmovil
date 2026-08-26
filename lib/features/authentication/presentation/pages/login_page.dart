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
              final mediaQuery = MediaQuery.of(context);
              final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
              final layout = _LoginLayout.resolve(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                textScale: mediaQuery.textScaler.scale(1),
              );
              final needsScroll =
                  keyboardOpen || constraints.maxHeight < layout.minimumHeight;
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
                          _LoginHeader(layout: layout),
                          Transform.translate(
                            offset: Offset(0, -layout.overlap),
                            child: _LoginForm(
                              layout: layout,
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

class _LoginLayout {
  const _LoginLayout({
    required this.headerHeight,
    required this.minimumHeight,
    required this.overlap,
    required this.formTopPadding,
    required this.formBottomPadding,
    required this.fieldGap,
    required this.beforeForgotGap,
    required this.beforeButtonGap,
    required this.beforeDividerGap,
    required this.afterDividerGap,
    required this.beforeSecurityGap,
    required this.beforeAccountGap,
    required this.loginButtonHeight,
    required this.socialButtonSize,
    required this.securityHeight,
    required this.headerScale,
    required this.titleSize,
  });

  factory _LoginLayout.resolve({
    required double height,
    required double width,
    required double textScale,
  }) {
    final scaleAllowance = ((textScale - 1).clamp(0, .25) * 80).toDouble();
    if (height >= 820) {
      return _LoginLayout(
        headerHeight: 290,
        minimumHeight: 790 + scaleAllowance,
        overlap: 26,
        formTopPadding: 27,
        formBottomPadding: 9,
        fieldGap: 14,
        beforeForgotGap: 20,
        beforeButtonGap: 15,
        beforeDividerGap: 30,
        afterDividerGap: 15,
        beforeSecurityGap: 21,
        beforeAccountGap: 15,
        loginButtonHeight: 56,
        socialButtonSize: 64,
        securityHeight: 64,
        headerScale: 1,
        titleSize: 30,
      );
    }
    if (height >= 720) {
      return _LoginLayout(
        headerHeight: 235,
        minimumHeight: 700 + scaleAllowance,
        overlap: 22,
        formTopPadding: 20,
        formBottomPadding: 6,
        fieldGap: 10,
        beforeForgotGap: 10,
        beforeButtonGap: 8,
        beforeDividerGap: 18,
        afterDividerGap: 10,
        beforeSecurityGap: 14,
        beforeAccountGap: 8,
        loginButtonHeight: 52,
        socialButtonSize: 56,
        securityHeight: 60,
        headerScale: width < 360 ? .78 : .82,
        titleSize: 28,
      );
    }
    return _LoginLayout(
      headerHeight: 185,
      minimumHeight: 610 + scaleAllowance,
      overlap: 18,
      formTopPadding: 12,
      formBottomPadding: 4,
      fieldGap: 6,
      beforeForgotGap: 4,
      beforeButtonGap: 2,
      beforeDividerGap: 8,
      afterDividerGap: 6,
      beforeSecurityGap: 8,
      beforeAccountGap: 2,
      loginButtonHeight: 48,
      socialButtonSize: 48,
      securityHeight: 56,
      headerScale: width < 360 ? .64 : .69,
      titleSize: 26,
    );
  }

  final double headerHeight;
  final double minimumHeight;
  final double overlap;
  final double formTopPadding;
  final double formBottomPadding;
  final double fieldGap;
  final double beforeForgotGap;
  final double beforeButtonGap;
  final double beforeDividerGap;
  final double afterDividerGap;
  final double beforeSecurityGap;
  final double beforeAccountGap;
  final double loginButtonHeight;
  final double socialButtonSize;
  final double securityHeight;
  final double headerScale;
  final double titleSize;

  double headerTop(double value) => value * headerScale;
  double headerBottom(double value) => value * headerScale;
  double headerSide(double value) => value * headerScale;
  double headerSize(double value) => value * headerScale;
  double get headerTitleTop => headerHeight < 200 ? 24 : headerTop(61);
  double get headerSubtitleTop => headerHeight < 200 ? 94 : headerTop(153);
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.layout});

  final _LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: layout.headerHeight,
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
            top: layout.headerTop(43),
            right: layout.headerSide(25),
            child: Hero(
              tag: 'app-logo',
              child: Image.asset(
                _chatHeartAsset,
                width: layout.headerSize(58),
                height: layout.headerSize(58),
              ),
            ),
          ),
          Positioned(
            top: layout.headerTitleTop,
            left: layout.headerSide(28),
            child: RichText(
              text: TextSpan(
                style: AppTypography.h1.copyWith(
                  fontSize: layout.titleSize,
                  height: 1.24,
                ),
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
            top: layout.headerSubtitleTop,
            left: layout.headerSide(28),
            child: Text(
              'Inicia sesión para continuar',
              style: AppTypography.bodySecondary.copyWith(fontSize: 14),
            ),
          ),
          Positioned(
            left: layout.headerSide(8),
            bottom: layout.headerBottom(18),
            child: Image.asset(
              _largePawAsset,
              width: layout.headerSize(61),
              height: layout.headerSize(56),
            ),
          ),
          Positioned(
            left: layout.headerSide(125),
            bottom: layout.headerBottom(53),
            child: Image.asset(
              _smallPawAsset,
              width: layout.headerSize(40),
              height: layout.headerSize(37),
            ),
          ),
          Positioned(
            right: -layout.headerSide(9),
            bottom: -layout.headerBottom(5),
            child: Container(
              width: layout.headerSize(170),
              height: layout.headerSize(170),
              decoration: const BoxDecoration(
                color: Color(0xFFDDEBFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -layout.headerSide(2),
            bottom: layout.headerBottom(6),
            width: layout.headerSize(193),
            height: layout.headerSize(181),
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
    required this.layout,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final _LoginLayout layout;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        layout.formTopPadding,
        24,
        layout.formBottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppEmailField(controller: emailController),
          SizedBox(height: layout.fieldGap),
          AppPasswordField(
            controller: passwordController,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: layout.beforeForgotGap),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  AppSnackBar.showInfo(context, 'Próximamente disponible.'),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          SizedBox(height: layout.beforeButtonGap),
          _LoginButton(
            label: 'Iniciar sesión',
            height: layout.loginButtonHeight,
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
          SizedBox(height: layout.beforeDividerGap),
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
          SizedBox(height: layout.afterDividerGap),
          _SocialLoginRow(buttonSize: layout.socialButtonSize),
          SizedBox(height: layout.beforeSecurityGap),
          _SecurityNotice(height: layout.securityHeight),
          SizedBox(height: layout.beforeAccountGap),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: AppTypography.bodySecondary,
                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.label,
    required this.height,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final double height;
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
              height: height,
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
  const _SocialLoginRow({required this.buttonSize});

  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    void showComingSoon() {
      AppSnackBar.showInfo(context, 'Próximamente disponible.');
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          size: buttonSize,
          onTap: showComingSoon,
          child: const SizedBox(
            width: 29,
            height: 29,
            child: CustomPaint(painter: _GoogleMarkPainter()),
          ),
        ),
        const SizedBox(width: 38),
        _SocialButton(
          size: buttonSize,
          onTap: showComingSoon,
          child: const Icon(Icons.apple_rounded, size: 27),
        ),
        const SizedBox(width: 38),
        _SocialButton(
          size: buttonSize,
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
  const _SocialButton({
    required this.onTap,
    required this.child,
    required this.size,
  });

  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
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
  const _SecurityNotice({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Tu información está segura',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Usamos encriptación de nivel bancario',
                    style: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
