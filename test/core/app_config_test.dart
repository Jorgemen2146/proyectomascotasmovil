import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
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
}
