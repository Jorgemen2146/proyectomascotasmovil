// Smoke test verifying the app boots to the splash screen without throwing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/main.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (tester) async {
    AppConfig.init(environment: Environment.dev);

    await tester.pumpWidget(const ProviderScope(child: DogPlatformApp()));
    await tester.pump();

    expect(find.text('DogPlatform', findRichText: true), findsOneWidget);
  });
}
