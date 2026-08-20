import '../config/app_config.dart';

class GatewayUrlResolver {
  GatewayUrlResolver._();

  static String resolve(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final candidate = value.trim();
    final uri = Uri.tryParse(candidate);
    if (uri != null && uri.hasScheme) return candidate;

    final base = AppConfig.instance.apiBaseUrl;
    return candidate.startsWith('/') ? '$base$candidate' : '$base/$candidate';
  }
}
