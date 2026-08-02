import 'environment.dart';

/// Centralized, environment-aware application configuration.
///
/// No base URL or environment-specific value should ever be hardcoded
/// outside of this file. The active environment is selected at build/run
/// time via `--dart-define=ENV=dev|qa|prod` (defaults to [Environment.dev]).
class AppConfig {
  AppConfig._({
    required this.environment,
    required this.identityBaseUrl,
    required this.petsBaseUrl,
    required this.genealogyBaseUrl,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
  });

  final Environment environment;

  /// Identity microservice base URL (authentication, users).
  final String identityBaseUrl;

  /// Pets microservice base URL.
  final String petsBaseUrl;

  /// Genealogy microservice base URL.
  final String genealogyBaseUrl;

  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  static AppConfig? _instance;

  /// Returns the currently active configuration. Must call [init] once
  /// during app startup (see `main.dart`) before accessing this getter.
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'AppConfig has not been initialized. Call AppConfig.init() first.',
      );
    }
    return config;
  }

  /// Initializes the singleton configuration for the given [environment].
  static AppConfig init({
    required Environment environment,
  }) {
    final config = switch (environment) {
      Environment.dev => AppConfig._(
          environment: Environment.dev,
          identityBaseUrl: 'https://api-dev.dogplatform.com/identity',
          petsBaseUrl: 'https://api-dev.dogplatform.com/pets',
          genealogyBaseUrl: 'https://api-dev.dogplatform.com/genealogy',
          connectTimeoutMs: 15000,
          receiveTimeoutMs: 15000,
        ),
      Environment.qa => AppConfig._(
          environment: Environment.qa,
          identityBaseUrl: 'https://api-qa.dogplatform.com/identity',
          petsBaseUrl: 'https://api-qa.dogplatform.com/pets',
          genealogyBaseUrl: 'https://api-qa.dogplatform.com/genealogy',
          connectTimeoutMs: 15000,
          receiveTimeoutMs: 15000,
        ),
      Environment.prod => AppConfig._(
          environment: Environment.prod,
          identityBaseUrl: 'https://api.dogplatform.com/identity',
          petsBaseUrl: 'https://api.dogplatform.com/pets',
          genealogyBaseUrl: 'https://api.dogplatform.com/genealogy',
          connectTimeoutMs: 10000,
          receiveTimeoutMs: 10000,
        ),
    };
    _instance = config;
    return config;
  }

  bool get isProd => environment == Environment.prod;
}
