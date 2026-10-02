import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_email_field.dart';
import '../../../../core/widgets/app_password_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../application/auth_state_controller.dart';
import '../../domain/entities/external_auth.dart';

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
  ExternalAuthProvider? _loadingProvider;

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

  Future<void> _socialLogin(ExternalAuthProvider provider) async {
    if (_loadingProvider != null) return;
    setState(() => _loadingProvider = provider);
    final outcome = await ref
        .read(authStateControllerProvider.notifier)
        .externalLogin(provider: provider);
    if (!mounted) return;
    setState(() => _loadingProvider = null);
    if (outcome is ExternalRegistrationRequired) {
      await context.push(
        AppRoutes.completeExternalRegistration,
        extra: outcome,
      );
    } else if (outcome == null) {
      final message = ref.read(authStateControllerProvider).errorMessage;
      if (message != null) AppSnackBar.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenSize = MediaQuery.sizeOf(context);
              final layout = _LoginLayout.resolve(
                height: screenSize.height,
                width: screenSize.width,
              );
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
                          _LoginForm(
                            layout: layout,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            isSubmitting: _isSubmitting,
                            onSubmit: _submit,
                            loadingProvider: _loadingProvider,
                            onSocialLogin: _socialLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: content,
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
    required this.headerTextHeight,
    required this.heroPetsHeight,
    required this.isCompact,
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
  }) {
    final heroPetsHeight = _resolveHeroPetsHeight(height: height, width: width);
    if (height >= 820) {
      return _LoginLayout(
        headerTextHeight: 132,
        heroPetsHeight: heroPetsHeight,
        isCompact: false,
        formTopPadding: 18,
        formBottomPadding: 8,
        fieldGap: 10,
        beforeForgotGap: 4,
        beforeButtonGap: 6,
        beforeDividerGap: 14,
        afterDividerGap: 10,
        beforeSecurityGap: 14,
        beforeAccountGap: 12,
        loginButtonHeight: 56,
        socialButtonSize: 52,
        securityHeight: 58,
        headerScale: 1,
        titleSize: 27,
      );
    }
    if (height >= 720) {
      final headerScale = width < 360 ? .9 : .95;
      return _LoginLayout(
        headerTextHeight: 132 * headerScale,
        heroPetsHeight: heroPetsHeight,
        isCompact: false,
        formTopPadding: 16,
        formBottomPadding: 6,
        fieldGap: 8,
        beforeForgotGap: 2,
        beforeButtonGap: 4,
        beforeDividerGap: 12,
        afterDividerGap: 10,
        beforeSecurityGap: 12,
        beforeAccountGap: 10,
        loginButtonHeight: 52,
        socialButtonSize: 50,
        securityHeight: 56,
        headerScale: headerScale,
        titleSize: 26,
      );
    }
    return _LoginLayout(
      headerTextHeight: 112,
      heroPetsHeight: heroPetsHeight,
      isCompact: true,
      formTopPadding: 8,
      formBottomPadding: 2,
      fieldGap: 4,
      beforeForgotGap: 2,
      beforeButtonGap: 2,
      beforeDividerGap: 6,
      afterDividerGap: 4,
      beforeSecurityGap: 6,
      beforeAccountGap: 6,
      loginButtonHeight: 48,
      socialButtonSize: 44,
      securityHeight: 52,
      headerScale: width < 360 ? .76 : .8,
      titleSize: 24,
    );
  }

  static const double minHeroPetsHeight = 152;
  static const double maxHeroPetsHeight = 220;

  static double _resolveHeroPetsHeight({
    required double height,
    required double width,
  }) {
    final widthBasedHeight = width * .52;
    final screenBasedHeight = height * .24;
    final preferredHeight = widthBasedHeight < screenBasedHeight
        ? widthBasedHeight
        : screenBasedHeight;
    return preferredHeight
        .clamp(minHeroPetsHeight, maxHeroPetsHeight)
        .toDouble();
  }

  final double headerTextHeight;
  final double heroPetsHeight;
  final bool isCompact;
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
  double get headerHeight => headerTextHeight + heroPetsHeight;
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader({required this.layout});

  final _LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: layout.headerHeight,
      child: Column(
        children: [
          SizedBox(
            height: layout.headerTextHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(top: layout.isCompact ? 8 : 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AppTypography.h1.copyWith(
                                  fontSize: layout.titleSize,
                                  height: 1.14,
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
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Inicia sesión para continuar',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySecondary.copyWith(
                            fontSize: layout.isCompact ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: layout.isCompact ? 6 : 12,
                  right: layout.headerSide(25),
                  child: Hero(
                    tag: 'app-logo',
                    child: Image.asset(
                      _chatHeartAsset,
                      width: layout.headerSize(48),
                      height: layout.headerSize(48),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _HeroPetsArea(layout: layout),
        ],
      ),
    );
  }
}

class _HeroPetsArea extends StatelessWidget {
  const _HeroPetsArea({required this.layout});

  final _LoginLayout layout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('loginHeroPetsArea'),
      height: layout.heroPetsHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surface, AppColors.background],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: ClipPath(
              clipper: _LoginHeaderWaveClipper(),
              child: ColoredBox(color: AppColors.primarySoft),
            ),
          ),
          Positioned(
            left: layout.headerSide(13),
            bottom: layout.headerBottom(10),
            child: Image.asset(
              _largePawAsset,
              width: layout.headerSize(61),
              height: layout.headerSize(56),
            ),
          ),
          Positioned(
            left: layout.headerSide(112),
            bottom: layout.headerBottom(38),
            child: Image.asset(
              _smallPawAsset,
              width: layout.headerSize(40),
              height: layout.headerSize(37),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: layout.heroPetsHeight,
                child: Image.asset(
                  _loginPetsAsset,
                  key: const Key('loginPetsImage'),
                  alignment: Alignment.bottomCenter,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeaderWaveClipper extends CustomClipper<Path> {
  const _LoginHeaderWaveClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height * .04)
      ..cubicTo(
        size.width * .16,
        size.height * .12,
        size.width * .16,
        size.height * .62,
        size.width * .48,
        size.height * .70,
      )
      ..cubicTo(
        size.width * .73,
        size.height * .80,
        size.width * .78,
        size.height * .35,
        size.width,
        size.height * .49,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.layout,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onSubmit,
    required this.loadingProvider,
    required this.onSocialLogin,
  });

  final _LoginLayout layout;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final ExternalAuthProvider? loadingProvider;
  final ValueChanged<ExternalAuthProvider> onSocialLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        layout.formTopPadding,
        AppSpacing.lg,
        layout.formBottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
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
              key: const Key('forgotPasswordLink'),
              onPressed: () => context.push(AppRoutes.forgotPassword),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          SizedBox(height: layout.beforeButtonGap),
          _LoginButton(
            key: const Key('loginSubmitButton'),
            label: 'Iniciar sesión',
            height: layout.loginButtonHeight,
            isLoading: isSubmitting,
            onPressed: onSubmit,
          ),
          SizedBox(height: layout.beforeAccountGap),
          const _CreateAccountCard(),
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
          _SocialLoginRow(
            buttonSize: layout.socialButtonSize,
            loadingProvider: loadingProvider,
            onLogin: onSocialLogin,
          ),
          SizedBox(height: layout.beforeSecurityGap),
          _SecurityNotice(height: layout.securityHeight),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    super.key,
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
            colors: [AppColors.heroStart, AppColors.heroEnd],
          ),
          borderRadius: AppRadius.mdAll,
          boxShadow: AppShadows.soft,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: AppRadius.mdAll,
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

class _CreateAccountCard extends StatelessWidget {
  const _CreateAccountCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        key: const Key('createAccountCard'),
        onTap: () => context.push(AppRoutes.register),
        borderRadius: AppRadius.lgAll,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.compact,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.primary.withValues(alpha: .42)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.pets,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: AppSpacing.compact),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿No tienes cuenta?', style: AppTypography.caption),
                    Text(
                      'Crea tu cuenta',
                      style: AppTypography.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                AppIcons.chevronRight,
                color: AppColors.primary,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLoginRow extends StatelessWidget {
  const _SocialLoginRow({
    required this.buttonSize,
    required this.loadingProvider,
    required this.onLogin,
  });

  final double buttonSize;
  final ExternalAuthProvider? loadingProvider;
  final ValueChanged<ExternalAuthProvider> onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          key: const Key('googleLoginButton'),
          size: buttonSize,
          onTap: loadingProvider == null
              ? () => onLogin(ExternalAuthProvider.google)
              : null,
          isLoading: loadingProvider == ExternalAuthProvider.google,
          child: const SizedBox(
            width: 29,
            height: 29,
            child: CustomPaint(painter: _GoogleMarkPainter()),
          ),
        ),
        const SizedBox(width: 38),
        _SocialButton(
          key: const Key('appleLoginButton'),
          size: buttonSize,
          onTap: loadingProvider == null
              ? () => onLogin(ExternalAuthProvider.apple)
              : null,
          isLoading: loadingProvider == ExternalAuthProvider.apple,
          child: const Icon(Icons.apple_rounded, size: 27),
        ),
        const SizedBox(width: 38),
        _SocialButton(
          key: const Key('facebookLoginButton'),
          size: buttonSize,
          onTap: loadingProvider == null
              ? () => onLogin(ExternalAuthProvider.facebook)
              : null,
          isLoading: loadingProvider == ExternalAuthProvider.facebook,
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
    super.key,
    required this.onTap,
    required this.child,
    required this.size,
    required this.isLoading,
  });

  final VoidCallback? onTap;
  final Widget child;
  final double size;
  final bool isLoading;

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
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : child,
          ),
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
