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
      GatewayUrlResolver.resolve('/uploads/pet.jpg'),
      'http://gateway.test/uploads/pet.jpg',
    );
    expect(
      GatewayUrlResolver.resolve('https://cdn.example.test/pet.jpg'),
      'https://cdn.example.test/pet.jpg',
    );
  });
}
