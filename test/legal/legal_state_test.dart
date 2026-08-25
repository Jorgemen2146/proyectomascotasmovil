import 'package:dogplatform/features/legal/application/providers.dart';
import 'package:dogplatform/features/legal/domain/entities/legal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dogplatform/features/authentication/application/auth_state_controller.dart';
import 'package:dogplatform/features/authentication/application/providers.dart';

import '../helpers/fake_auth_repository.dart';
import 'fakes.dart';

void main() {
  test('legal status up-to-date', () async {
    final repository = FakeLegalRepository();
    final container = ProviderContainer(
      overrides: [legalRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final status = await container.read(legalStatusProvider.future);

    expect(status.isUpToDate, isTrue);
    expect(status.pendingDocuments, isEmpty);
  });

  test('legal status conserva múltiples documentos pendientes', () async {
    final repository = FakeLegalRepository()
      ..status = LegalStatus(
        isUpToDate: false,
        pendingDocuments: sampleLegalDocuments,
      );
    final container = ProviderContainer(
      overrides: [legalRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final status = await container.read(legalStatusProvider.future);

    expect(status.isUpToDate, isFalse);
    expect(status.pendingDocuments, hasLength(2));
  });

  test('acceptDocument envía ID real e invalida status', () async {
    final repository = FakeLegalRepository();
    final container = ProviderContainer(
      overrides: [legalRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(legalStatusProvider.future);

    final result = await container
        .read(legalControllerProvider.notifier)
        .acceptDocument('privacy-id');
    await container.read(legalStatusProvider.future);

    expect(result.isSuccess, isTrue);
    expect(repository.acceptedIds, ['privacy-id']);
    expect(repository.statusCalls, 2);
  });

  test('logout invalida el estado legal personal', () async {
    final legal = FakeLegalRepository();
    final auth = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        legalRepositoryProvider.overrideWithValue(legal),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(legalStatusProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(legalStatusProvider.future);

    await container.read(authStateControllerProvider.notifier).logout();
    await container.read(legalStatusProvider.future);

    expect(legal.statusCalls, 2);
  });
}
