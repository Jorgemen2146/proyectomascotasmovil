import 'package:dogplatform/features/genealogy/application/providers.dart';
import 'package:dogplatform/features/genealogy/presentation/pages/genealogy_invitations_page.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('lista solicitudes recibidas con su estado', (tester) async {
    final repository = FakeGenealogyRepository()
      ..invitations = [incomingInvitation];
    await _pump(tester, repository: repository);

    expect(find.text('Andrea Kitty'), findsOneWidget);
    expect(find.text('Madre · Pendiente'), findsOneWidget);
  });

  testWidgets('lista enviadas y permite cancelar una pendiente', (
    tester,
  ) async {
    final repository = FakeGenealogyRepository()
      ..invitations = [pendingInvitation];
    await _pump(tester, repository: repository);

    await tester.tap(find.text('Enviadas'));
    await tester.pumpAndSettle();
    expect(find.text('Andrea Kitty'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancelInvitation-invitation-1')));
    await tester.pumpAndSettle();

    expect(repository.cancelledInvitationId, 'invitation-1');
  });

  testWidgets('token externo carga contexto y permite aceptar', (tester) async {
    final repository = FakeGenealogyRepository();
    await _pump(
      tester,
      repository: repository,
      invitationToken: 'external-token',
    );

    expect(find.text('Solicitud genealógica'), findsOneWidget);
    await tester.tap(find.byKey(const Key('invitationPetSelector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tom').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('acceptInvitation')));
    await tester.pumpAndSettle();

    expect(repository.acceptedToken, 'external-token');
    expect(repository.acceptedPetId, 'father');
  });

  testWidgets('token externo permite rechazar', (tester) async {
    final repository = FakeGenealogyRepository();
    await _pump(
      tester,
      repository: repository,
      invitationToken: 'reject-token',
    );

    await tester.tap(find.byKey(const Key('rejectInvitation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rechazar').last);
    await tester.pumpAndSettle();

    expect(repository.rejectedToken, 'reject-token');
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeGenealogyRepository repository,
  String? invitationToken,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        genealogyRepositoryProvider.overrideWithValue(repository),
        myPetsProvider.overrideWith((ref) async => samplePets),
      ],
      child: MaterialApp(
        home: GenealogyInvitationsPage(invitationToken: invitationToken),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
