import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/auth_state.dart';
import '../../features/authentication/application/auth_state_controller.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../widgets/placeholder_page.dart';
import 'app_routes.dart';
import 'go_router_refresh_notifier.dart';

/// Application-wide GoRouter configuration. Only Splash/Login/Register/Home
/// are fully implemented; Pets/Profile/Genealogy/Matching/Health are wired
/// as placeholder routes ready for their features to be built out.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(goRouterRefreshNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.pets,
        builder: (context, state) => const PlaceholderPage(title: 'Pets'),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const PlaceholderPage(title: 'Profile'),
      ),
      GoRoute(
        path: AppRoutes.genealogy,
        builder: (context, state) => const PlaceholderPage(title: 'Genealogy'),
      ),
      GoRoute(
        path: AppRoutes.matching,
        builder: (context, state) => const PlaceholderPage(title: 'Matching'),
      ),
      GoRoute(
        path: AppRoutes.health,
        builder: (context, state) => const PlaceholderPage(title: 'Health'),
      ),
    ],
  );
});

String? _redirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authStateControllerProvider);
  final location = state.matchedLocation;
  final isSplash = location == AppRoutes.splash;
  final isAuthRoute = location == AppRoutes.login || location == AppRoutes.register;

  switch (authState.status) {
    case AuthStatus.unknown:
      return isSplash ? null : AppRoutes.splash;
    case AuthStatus.unauthenticated:
      return isAuthRoute ? null : AppRoutes.login;
    case AuthStatus.authenticated:
      return (isSplash || isAuthRoute) ? AppRoutes.home : null;
  }
}
