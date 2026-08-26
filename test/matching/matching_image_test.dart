import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/core/network/gateway_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resuelve imágenes Matching mediante GatewayUrlResolver', () {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'https://gateway.example.test',
    );
    expect(
      GatewayUrlResolver.resolve('/api/v1/pets/pet-1/photos/photo-1/content'),
      'https://gateway.example.test/api/v1/pets/pet-1/photos/photo-1/content',
    );
  });
}
