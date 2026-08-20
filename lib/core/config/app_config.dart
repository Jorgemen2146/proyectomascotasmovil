import 'environment.dart';

/// Centralized, environment-aware application configuration.
///
/// No base URL or environment-specific value should ever be hardcoded
/// outside of this file. The active environment is selected at build/run
/// time via `--dart-define=ENV=dev|qa|prod` (defaults to [Environment.dev]).
class AppConfig {
  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
  });

  final Environment environment;

  /// Single public entry point for every backend API.
  final String apiBaseUrl;

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
    String? apiBaseUrl,
  }) {
    const definedBaseUrl = String.fromEnvironment('API_BASE_URL');
    final override = apiBaseUrl ?? definedBaseUrl;
    final defaultBaseUrl = switch (environment) {
      Environment.dev => 'http://10.0.2.2:5101',
      Environment.qa => 'https://api-qa.dogplatform.com',
      Environment.prod => 'https://api.dogplatform.com',
    };
    final resolvedBaseUrl = (override.isEmpty ? defaultBaseUrl : override)
        .replaceFirst(RegExp(r'/+$'), '');
    final config = switch (environment) {
      Environment.dev => AppConfig._(
        environment: Environment.dev,
        apiBaseUrl: resolvedBaseUrl,
        connectTimeoutMs: 15000,
        receiveTimeoutMs: 15000,
      ),
      Environment.qa => AppConfig._(
        environment: Environment.qa,
        apiBaseUrl: resolvedBaseUrl,
        connectTimeoutMs: 15000,
        receiveTimeoutMs: 15000,
      ),
      Environment.prod => AppConfig._(
        environment: Environment.prod,
        apiBaseUrl: resolvedBaseUrl,
        connectTimeoutMs: 10000,
        receiveTimeoutMs: 10000,
      ),
    };
    _instance = config;
    return config;
  }

  bool get isProd => environment == Environment.prod;
}
