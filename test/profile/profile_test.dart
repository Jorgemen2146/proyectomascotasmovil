import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/authentication/domain/entities/user.dart';
import 'package:dogplatform/features/profile/application/profile_controller.dart';
import 'package:dogplatform/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:dogplatform/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository()
      ..currentUserResult = const Result.success(
        User(
          id: '1',
          email: 'jorge@example.com',
          fullName: 'Jorge Gonzales',
          phoneNumber: '+51 999 999 999',
        ),
      );
  });

  testWidgets('perfil muestra usuario y correo verificado', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jorge Gonzales'), findsOneWidget);
    expect(find.text('jorge@example.com'), findsOneWidget);
    expect(find.text('Correo verificado'), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
  });

  testWidgets('editar perfil precarga datos y mantiene email readonly', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Jorge'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Gonzales'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'jorge@example.com'),
      findsOneWidget,
    );
    final emailFormField = find.widgetWithText(
      TextFormField,
      'jorge@example.com',
    );
    final emailField = tester.widget<TextField>(
      find.descendant(of: emailFormField, matching: find.byType(TextField)),
    );
    expect(emailField.readOnly, isTrue);
  });

  test('controller actualiza perfil e incluye teléfono', () async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(profileControllerProvider.future);

    final success = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: 'Jorge',
          lastName: 'Actualizado',
          phoneNumber: '+51 987 654 321',
        );

    expect(success, isTrue);
    expect(
      container.read(profileControllerProvider).value?.fullName,
      'Jorge Actualizado',
    );
    expect(
      container.read(profileControllerProvider).value?.phoneNumber,
      '+51 987 654 321',
    );
  });
}
