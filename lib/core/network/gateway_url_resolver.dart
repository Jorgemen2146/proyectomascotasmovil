import '../config/app_config.dart';

class GatewayUrlResolver {
  GatewayUrlResolver._();

  static String resolve(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final candidate = value.trim();
    final uri = Uri.tryParse(candidate);
    if (uri != null && uri.hasScheme) {
      if (_isLocalGatewayAlias(uri)) {
        return _replaceOrigin(uri);
      }
      return candidate;
    }

    final base = AppConfig.instance.apiBaseUrl;
    return candidate.startsWith('/') ? '$base$candidate' : '$base/$candidate';
  }

  /// Whether [value] is served by the configured API Gateway and therefore
  /// requires the application's bearer token.
  ///
  /// External pre-signed storage URLs deliberately return `false`, preventing
  /// the Authorization header from leaking to S3 or another storage provider.
  static bool isGatewayUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) return true;

    final gateway = Uri.parse(AppConfig.instance.apiBaseUrl);
    return _sameOrigin(uri, gateway) || _isLocalGatewayAlias(uri);
  }

  static bool _isLocalGatewayAlias(Uri candidate) {
    final gateway = Uri.parse(AppConfig.instance.apiBaseUrl);
    if (!_isLoopbackAlias(candidate.host) || !_isLoopbackAlias(gateway.host)) {
      return false;
    }
    return candidate.scheme == gateway.scheme &&
        candidate.port == gateway.port &&
        candidate.path.startsWith('/api/v1/');
  }

  static bool _isLoopbackAlias(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';

  static bool _sameOrigin(Uri first, Uri second) =>
      first.scheme == second.scheme &&
      first.host == second.host &&
      first.port == second.port;

  static String _replaceOrigin(Uri candidate) {
    final gateway = Uri.parse(AppConfig.instance.apiBaseUrl);
    return candidate
        .replace(
          scheme: gateway.scheme,
          host: gateway.host,
          port: gateway.hasPort ? gateway.port : null,
        )
        .toString();
  }
}
