import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/core/network/gateway_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('apiBaseUrl dev usa el API Gateway del Android Emulator', () {
    final config = AppConfig.init(environment: Environment.dev);

    expect(config.apiBaseUrl, 'http://10.0.2.2:5101');
  });

  test('apiBaseUrl acepta override y elimina slash final', () {
    final config = AppConfig.init(
      environment: Environment.qa,
      apiBaseUrl: 'https://gateway.example.test/',
    );

    expect(config.apiBaseUrl, 'https://gateway.example.test');
  });

  test('resolver conserva URLs absolutas y resuelve relativas por Gateway', () {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'http://gateway.test',
    );

    expect(
      GatewayUrlResolver.resolve('/api/v1/pets/pet-1/photos/photo-1/content'),
      'http://gateway.test/api/v1/pets/pet-1/photos/photo-1/content',
    );
    expect(
      GatewayUrlResolver.resolve('https://cdn.example.test/pet.jpg'),
      'https://cdn.example.test/pet.jpg',
    );
    expect(
      GatewayUrlResolver.isGatewayUrl(
        '/api/v1/pets/pet-1/photos/photo-1/content',
      ),
      isTrue,
    );
    expect(
      GatewayUrlResolver.isGatewayUrl('https://cdn.example.test/pet.jpg'),
      isFalse,
    );
  });

  test('resolver adapta localhost del Gateway al host del emulador', () {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'http://10.0.2.2:5101',
    );

    const localPhoto =
        'http://localhost:5101/api/v1/pets/pet-1/photos/content/key';
    expect(GatewayUrlResolver.isGatewayUrl(localPhoto), isTrue);
    expect(
      GatewayUrlResolver.resolve(localPhoto),
      'http://10.0.2.2:5101/api/v1/pets/pet-1/photos/content/key',
    );
  });
}
