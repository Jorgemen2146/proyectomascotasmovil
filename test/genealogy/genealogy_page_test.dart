import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/features/genealogy/application/providers.dart';
import 'package:dogplatform/features/genealogy/domain/entities/genealogy.dart';
import 'package:dogplatform/features/genealogy/presentation/pages/genealogy_page.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes.dart';

void main() {
  setUpAll(() {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'http://10.0.2.2:5101',
    );
  });

  testWidgets('renderiza raíz, padre, madre, hijos y scroll local', (
    tester,
  ) async {
    await _pumpPage(tester, tree: sampleTree);

    expect(find.text('Andrea Kitty'), findsWidgets);
    expect(find.text('Tom'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(
      find.byKey(const Key('genealogyTreeHorizontalScroll')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const Key('genealogyPageList')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nina'), findsOneWidget);
  });

  testWidgets('árbol vacío muestra ambos CTAs y mensaje', (tester) async {
    await _pumpPage(tester, tree: emptyTree);

    expect(find.byKey(const Key('add-father')), findsOneWidget);
    expect(find.byKey(const Key('add-mother')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('genealogyPageList')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.text('No hay relaciones registradas todavía'), findsOneWidget);
  });

  testWidgets('agrega un progenitor desde mascotas propias', (tester) async {
    final repository = FakeGenealogyRepository()..tree = emptyTree;
    await _pumpPage(tester, tree: emptyTree, repository: repository);

    await tester.tap(find.byKey(const Key('add-father')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('parentSourceOwnPet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('parentCandidate-father')));
    await tester.pumpAndSettle();

    expect(repository.addedParentId, 'father');
    expect(repository.addedRole, GenealogyParentRole.father);
    expect(find.text('Relación guardada correctamente.'), findsOneWidget);
  });

  testWidgets('invitación pendiente no modifica el árbol', (tester) async {
    final repository = FakeGenealogyRepository()..tree = emptyTree;
    await _pumpPage(tester, tree: emptyTree, repository: repository);

    await tester.tap(find.byKey(const Key('add-mother')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('parentSourceExternal')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('invitationEmail')),
      'owner@example.com',
    );
    await tester.tap(find.byKey(const Key('sendGenealogyInvitation')));
    await tester.pumpAndSettle();

    expect(repository.invitedEmail, 'owner@example.com');
    expect(repository.addedParentId, isNull);
    expect(find.byKey(const Key('add-mother')), findsOneWidget);
  });

  testWidgets('elimina usando relationshipId después de confirmar', (
    tester,
  ) async {
    final repository = FakeGenealogyRepository();
    await _pumpPage(tester, tree: sampleTree, repository: repository);

    await tester.tap(find.byKey(const Key('genealogyNode-father')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deleteGenealogyRelationship')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(repository.deletedRelationshipId, 'rel-father');
  });

  testWidgets('centra la mascota raíz en viewport móvil', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpPage(tester, tree: emptyTree);

    final center = tester.getCenter(
      find.byKey(const Key('genealogyNode-root')),
    );
    expect(center.dx, inInclusiveRange(120, 270));
  });

  testWidgets('abre el árbol de una mascota relacionada', (tester) async {
    final router = GoRouter(
      initialLocation: '/genealogy?petId=root',
      routes: [
        GoRoute(
          path: '/genealogy',
          builder: (_, state) {
            final petId = state.uri.queryParameters['petId'];
            return petId == 'root'
                ? const GenealogyPage(initialPetId: 'root')
                : Scaffold(body: Text('Árbol $petId'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPetsProvider.overrideWith((ref) async => samplePets),
          genealogyTreeProvider.overrideWith((ref, query) async => sampleTree),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('genealogyNode-father')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver su árbol'));
    await tester.pumpAndSettle();

    expect(find.text('Árbol father'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required GenealogyTree tree,
  FakeGenealogyRepository? repository,
}) async {
  final fake = repository ?? FakeGenealogyRepository();
  fake.tree = tree;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myPetsProvider.overrideWith((ref) async => samplePets),
        genealogyRepositoryProvider.overrideWithValue(fake),
        genealogyTreeProvider.overrideWith((ref, query) async => tree),
      ],
      child: const MaterialApp(home: GenealogyPage(initialPetId: 'root')),
    ),
  );
  await tester.pumpAndSettle();
}
