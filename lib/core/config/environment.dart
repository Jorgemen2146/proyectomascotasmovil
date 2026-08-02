/// Supported runtime environments for the application.
enum Environment { dev, qa, prod }

/// Extension helpers to parse an [Environment] from a raw string,
/// typically supplied via `--dart-define=ENV=dev`.
extension EnvironmentParsing on String {
  Environment toEnvironment() {
    switch (toLowerCase()) {
      case 'qa':
        return Environment.qa;
      case 'prod':
        return Environment.prod;
      case 'dev':
      default:
        return Environment.dev;
    }
  }
}
