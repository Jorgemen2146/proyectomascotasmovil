import 'dart:typed_data';

import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/core/network/network_providers.dart';
import 'package:dogplatform/core/network/gateway_url_resolver.dart';
import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/core/services/photo_picker_service.dart';
import 'package:dogplatform/core/storage/secure_token_storage.dart';
import 'package:dogplatform/core/widgets/app_network_image.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';
import 'package:dogplatform/features/authentication/domain/entities/user.dart';
import 'package:dogplatform/features/profile/application/profile_controller.dart';
import 'package:dogplatform/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:dogplatform/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:dogplatform/core/router/app_routes.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUpAll(() {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'https://gateway.example.test',
    );
  });

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
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          secureTokenStorageProvider.overrideWithValue(_NoTokenStorage()),
        ],
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
    expect(find.byKey(const Key('profilePhotoSelector')), findsOneWidget);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
  });

  testWidgets('avatar abre opciones de cámara y galería', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: EditProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profilePhotoSelector')));
    await tester.pumpAndSettle();

    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de galería'), findsOneWidget);
  });

  testWidgets('perfil usa la URL de foto recibida', (tester) async {
    repository.currentUserResult = const Result.success(
      User(
        id: '1',
        email: 'jorge@example.com',
        fullName: 'Jorge Gonzales',
        profilePhotoUrl: '/api/v1/auth/me/photo/content',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          secureTokenStorageProvider.overrideWithValue(_NoTokenStorage()),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pump();

    final image = tester.widget<AppNetworkImage>(find.byType(AppNetworkImage));
    expect(image.url, '/api/v1/auth/me/photo/content');
    expect(
      GatewayUrlResolver.resolve(image.url),
      'https://gateway.example.test/api/v1/auth/me/photo/content',
    );
  });

  testWidgets('perfil abre Términos y Privacidad', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const ProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.legalTerms,
          builder: (_, _) =>
              const Text('legal-terms', textDirection: TextDirection.ltr),
        ),
        GoRoute(
          path: AppRoutes.legalPrivacy,
          builder: (_, _) =>
              const Text('legal-privacy', textDirection: TextDirection.ltr),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final termsLink = find.text('Términos y condiciones');
    await tester.ensureVisible(termsLink);
    await tester.tap(termsLink);
    await tester.pumpAndSettle();
    expect(find.text('legal-terms'), findsOneWidget);

    router.go(AppRoutes.profile);
    await tester.pumpAndSettle();
    final privacyLink = find.text('Privacidad');
    await tester.ensureVisible(privacyLink);
    await tester.tap(privacyLink);
    await tester.pumpAndSettle();
    expect(find.text('legal-privacy'), findsOneWidget);
  });

  test('controller actualiza perfil e incluye teléfono', () async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(profileControllerProvider.future);

    final outcome = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: 'Jorge',
          lastName: 'Actualizado',
          phoneNumber: '+51 987 654 321',
        );

    expect(outcome, isNotNull);
    expect(outcome?.photoFailure, isNull);
    expect(
      container.read(profileControllerProvider).value?.fullName,
      'Jorge Actualizado',
    );
    expect(
      container.read(profileControllerProvider).value?.phoneNumber,
      '+51 987 654 321',
    );
  });

  test('controller guarda datos, foto y luego refresca perfil', () async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(profileControllerProvider.future);
    repository.profileEvents.clear();
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final outcome = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: 'Jorge',
          lastName: 'Gonzales',
          phoneNumber: '+51 999 999 999',
          photo: SelectedPhoto(
            file: XFile.fromData(bytes, name: 'jorge.jpg'),
            fileName: 'jorge.jpg',
            contentType: 'image/jpeg',
            fileSize: bytes.length,
          ),
        );

    expect(outcome?.photoFailure, isNull);
    expect(repository.profileEvents, [
      'updateProfile',
      'uploadProfilePhoto',
      'getCurrentUser',
    ]);
    expect(
      container.read(profileControllerProvider).value?.profilePhotoUrl,
      '/api/v1/auth/me/photo/content',
    );
  });

  test('fallo de foto conserva datos actualizados y errorId', () async {
    repository.uploadProfilePhotoResult = const Result.failure(
      ServerFailure('falló foto', statusCode: 500, errorCode: 'PHOTO-123'),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(profileControllerProvider.future);

    final outcome = await container
        .read(profileControllerProvider.notifier)
        .updateProfile(
          firstName: 'Jorge',
          lastName: 'Actualizado',
          phoneNumber: null,
          photo: _selectedPhoto(),
        );

    expect(outcome?.photoFailure, isA<ServerFailure>());
    expect((outcome?.photoFailure as ServerFailure).errorCode, 'PHOTO-123');
    expect(
      container.read(profileControllerProvider).value?.fullName,
      'Jorge Actualizado',
    );
  });
}

class _NoTokenStorage extends SecureTokenStorage {
  @override
  Future<String?> readAccessToken() async => null;
}

SelectedPhoto _selectedPhoto() {
  final bytes = Uint8List.fromList([1]);
  return SelectedPhoto(
    file: XFile.fromData(bytes, name: 'profile.jpg'),
    fileName: 'profile.jpg',
    contentType: 'image/jpeg',
    fileSize: bytes.length,
  );
}
