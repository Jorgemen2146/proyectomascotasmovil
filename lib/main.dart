import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/environment.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Entry point. The active environment is selected via
/// `--dart-define=ENV=dev|qa|prod` (defaults to dev when not provided).
void main() {
  const envName = String.fromEnvironment('ENV', defaultValue: 'dev');
  AppConfig.init(environment: envName.toEnvironment());

  runApp(const ProviderScope(child: DogPlatformApp()));
}

class DogPlatformApp extends ConsumerWidget {
  const DogPlatformApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DogPlatform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
