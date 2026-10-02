import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/environment.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/application/auth_state.dart';
import 'features/authentication/application/auth_state_controller.dart';
import 'features/notifications/application/providers.dart';

/// Entry point. The active environment is selected via
/// `--dart-define=ENV=dev|qa|prod` (defaults to dev when not provided).
void main() {
  const envName = String.fromEnvironment('ENV', defaultValue: 'dev');
  AppConfig.init(environment: envName.toEnvironment());

  runApp(const ProviderScope(child: DogPlatformApp()));
}

class DogPlatformApp extends ConsumerStatefulWidget {
  const DogPlatformApp({super.key});

  @override
  ConsumerState<DogPlatformApp> createState() => _DogPlatformAppState();
}

class _DogPlatformAppState extends ConsumerState<DogPlatformApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (ref.read(authStateControllerProvider).status !=
        AuthStatus.authenticated) {
      return;
    }
    final controller = ref.read(notificationsControllerProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      controller.resumeFromBackground();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      controller.pauseRealtime();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationsSessionCoordinatorProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PetLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
