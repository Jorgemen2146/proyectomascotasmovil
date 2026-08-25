import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/core/network/gateway_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resuelve mainPhotoUrl relativo contra el Gateway configurado', () {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'http://10.0.2.2:5101',
    );

    expect(
      GatewayUrlResolver.resolve('/api/v1/pets/pet-1/photos/main.jpg'),
      'http://10.0.2.2:5101/api/v1/pets/pet-1/photos/main.jpg',
    );
  });
}
