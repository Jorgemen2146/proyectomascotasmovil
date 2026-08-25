import 'package:dogplatform/features/genealogy/application/providers.dart';
import 'package:dogplatform/features/genealogy/domain/entities/genealogy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('agrega progenitor propio e invalida el árbol afectado', () async {
    final repository = FakeGenealogyRepository();
    final container = ProviderContainer(
      overrides: [genealogyRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final query = (petId: 'root', generations: 3);
    await container.read(genealogyTreeProvider(query).future);

    final result = await container
        .read(genealogyControllerProvider.notifier)
        .addParent(
          childPetId: 'root',
          generations: 3,
          role: GenealogyParentRole.father,
          parentPetId: 'father',
        );
    await container.read(genealogyTreeProvider(query).future);

    expect(result.isSuccess, isTrue);
    expect(repository.addedChildId, 'root');
    expect(repository.addedParentId, 'father');
    expect(repository.addedRole, GenealogyParentRole.father);
    expect(repository.getTreeCalls, 2);
  });

  test('crea, acepta, rechaza y cancela invitaciones', () async {
    final repository = FakeGenealogyRepository();
    final container = ProviderContainer(
      overrides: [genealogyRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final controller = container.read(genealogyControllerProvider.notifier);

    await controller.createInvitation(
      childPetId: 'root',
      role: GenealogyParentRole.mother,
      ownerEmail: 'owner@example.com',
    );
    await controller.acceptInvitation(token: 'accept-token', petId: 'mother');
    await controller.rejectInvitation('reject-token');
    await controller.cancelInvitation('invitation-1');

    expect(repository.invitedEmail, 'owner@example.com');
    expect(repository.acceptedToken, 'accept-token');
    expect(repository.acceptedPetId, 'mother');
    expect(repository.rejectedToken, 'reject-token');
    expect(repository.cancelledInvitationId, 'invitation-1');
  });

  test('elimina por relationshipId e invalida el árbol', () async {
    final repository = FakeGenealogyRepository();
    final container = ProviderContainer(
      overrides: [genealogyRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final query = (petId: 'root', generations: 2);
    await container.read(genealogyTreeProvider(query).future);

    await container
        .read(genealogyControllerProvider.notifier)
        .deleteRelationship(
          relationshipId: 'rel-father',
          petId: 'root',
          generations: 2,
        );
    await container.read(genealogyTreeProvider(query).future);

    expect(repository.deletedRelationshipId, 'rel-father');
    expect(repository.getTreeCalls, 2);
  });
}
