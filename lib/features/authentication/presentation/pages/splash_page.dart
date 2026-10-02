import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/auth_state_controller.dart';

const _splashBackgroundAsset = 'assets/images/11_splash_background.png';
const _splashLandscapeAsset = 'assets/images/12_splash_landscape.png';
const _splashPetsAsset = 'assets/images/02_dog_cat_splash.png';
const _splashHeartAsset = 'assets/images/10_splash_heart.png';
const _pawCircleAsset = 'assets/images/06_paw_circle_icon.png';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeOut),
  );
  late final Animation<double> _scale = Tween(
    begin: 0.85,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateControllerProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final compact = height < 700;
            final whitePanelHeight = compact ? 132.0 : 157.0;
            final landscapeHeight = compact ? 245.0 : height * 0.37;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -31,
                  bottom: -31,
                  left: -18,
                  right: -18,
                  child: Image.asset(
                    _splashBackgroundAsset,
                    fit: BoxFit.fill,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  top: compact ? 68 : height * 0.187,
                  left: 24,
                  right: 24,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: const _SplashBrand(),
                    ),
                  ),
                ),
                Positioned(
                  left: -25,
                  right: -25,
                  bottom: whitePanelHeight - 15,
                  height: landscapeHeight,
                  child: Image.asset(
                    _splashLandscapeAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: 37,
                  right: 37,
                  bottom: whitePanelHeight - 8,
                  height: compact ? 252 : height * 0.35,
                  child: Image.asset(
                    _splashPetsAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: whitePanelHeight,
                  child: const ColoredBox(color: Colors.white),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: whitePanelHeight - 3,
                  height: 78,
                  child: const _SplashBottomWave(),
                ),
                Positioned(
                  left: 54,
                  right: 62,
                  bottom: compact ? 27 : 50,
                  child: const _SplashProgress(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: 'app-logo',
          child: SizedBox(
            width: 112,
            height: 102,
            child: const CustomPaint(painter: _SplashLogoPainter()),
          ),
        ),
        const SizedBox(height: 19),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.h1.copyWith(
              fontSize: 35,
              height: 1.05,
              color: Colors.white,
            ),
            children: const [
              TextSpan(text: 'Pet'),
              TextSpan(
                text: 'Life',
                style: TextStyle(color: Color(0xFF50C7F4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Text(
          'Conectando familias y\nsus mascotas',
          style: AppTypography.body.copyWith(
            color: Colors.white,
            fontSize: 17,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 13),
        ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0.75,
            0,
            0,
            0,
            0,
            0.95,
            0,
            -2,
            1,
            1,
            0,
            0,
          ]),
          child: Image.asset(_splashHeartAsset, width: 27, height: 28),
        ),
      ],
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  const _SplashLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final house = Path()
      ..moveTo(size.width * 0.18, size.height * 0.88)
      ..lineTo(size.width * 0.18, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.40,
        size.width * 0.24,
        size.height * 0.35,
      )
      ..lineTo(size.width * 0.46, size.height * 0.15)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.11,
        size.width * 0.54,
        size.height * 0.15,
      )
      ..lineTo(size.width * 0.76, size.height * 0.35)
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.40,
        size.width * 0.82,
        size.height * 0.48,
      )
      ..lineTo(size.width * 0.82, size.height * 0.88);
    canvas.drawPath(house, stroke);

    for (final toe in [
      Offset(size.width * 0.36, size.height * 0.52),
      Offset(size.width * 0.46, size.height * 0.46),
      Offset(size.width * 0.56, size.height * 0.46),
      Offset(size.width * 0.66, size.height * 0.52),
    ]) {
      canvas.drawCircle(toe, size.width * 0.045, fill);
    }

    final pad = Path()
      ..moveTo(size.width * 0.35, size.height * 0.77)
      ..cubicTo(
        size.width * 0.37,
        size.height * 0.65,
        size.width * 0.44,
        size.height * 0.58,
        size.width * 0.51,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.58,
        size.width * 0.65,
        size.height * 0.65,
        size.width * 0.67,
        size.height * 0.77,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.86,
        size.width * 0.59,
        size.height * 0.84,
        size.width * 0.51,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.43,
        size.height * 0.84,
        size.width * 0.34,
        size.height * 0.86,
        size.width * 0.35,
        size.height * 0.77,
      )
      ..close();
    canvas.drawPath(pad, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashBottomWave extends StatelessWidget {
  const _SplashBottomWave();

  @override
  Widget build(BuildContext context) {
    return const ClipPath(
      clipper: _SplashWaveClipper(),
      child: ColoredBox(color: Colors.white),
    );
  }
}

class _SplashWaveClipper extends CustomClipper<Path> {
  const _SplashWaveClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.76,
        size.width * 0.72,
        size.height * 1.06,
        size.width,
        size.height * 0.22,
      )
      ..lineTo(size.width, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Image.asset(_pawCircleAsset, width: 45, height: 45),
            const SizedBox(width: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const SizedBox(
                  height: 7,
                  child: LinearProgressIndicator(
                    value: 0.5,
                    backgroundColor: Color(0xFFE3E6EC),
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Cargando experiencia...',
          style: AppTypography.bodySecondary.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}
