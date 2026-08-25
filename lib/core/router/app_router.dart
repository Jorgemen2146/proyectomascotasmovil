import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/application/auth_state.dart';
import '../../features/authentication/application/auth_state_controller.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/verify_email_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/health/presentation/pages/health_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/pets/presentation/pages/pet_detail_page.dart';
import '../../features/pets/presentation/pages/pet_form_page.dart';
import '../../features/pets/presentation/pages/pet_photos_page.dart';
import '../../features/pets/presentation/pages/pets_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../widgets/placeholder_page.dart';
import 'app_routes.dart';
import 'go_router_refresh_notifier.dart';

/// Application-wide GoRouter configuration and authentication redirects.
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
        path: AppRoutes.verifyEmail,
        redirect: (context, state) {
          final email = state.extra as String?;
          return email == null || email.trim().isEmpty ? AppRoutes.login : null;
        },
        builder: (context, state) =>
            VerifyEmailPage(email: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.pets,
        builder: (context, state) => const PetsPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const PetFormPage(),
          ),
          GoRoute(
            path: ':petId',
            builder: (context, state) =>
                PetDetailPage(petId: state.pathParameters['petId']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    PetFormPage(petId: state.pathParameters['petId']!),
              ),
              GoRoute(
                path: 'photos',
                builder: (context, state) =>
                    PetPhotosPage(petId: state.pathParameters['petId']!),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfilePage(),
          ),
        ],
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
        builder: (context, state) =>
            HealthPage(initialPetId: state.uri.queryParameters['petId']),
      ),
    ],
  );
});

String? _redirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authStateControllerProvider);
  final location = state.matchedLocation;
  final isSplash = location == AppRoutes.splash;
  final isAuthRoute =
      location == AppRoutes.login ||
      location == AppRoutes.register ||
      location == AppRoutes.verifyEmail;

  switch (authState.status) {
    case AuthStatus.unknown:
      return isSplash ? null : AppRoutes.splash;
    case AuthStatus.unauthenticated:
      return isAuthRoute ? null : AppRoutes.login;
    case AuthStatus.authenticated:
      return (isSplash || isAuthRoute) ? AppRoutes.home : null;
  }
}
