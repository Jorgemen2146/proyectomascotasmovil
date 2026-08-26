import 'package:dogplatform/features/matching/application/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  test('acciones de camada invalidan y vuelven a consultar backend', () async {
    final repository = FakeMatchingRepository();
    final container = ProviderContainer(
      overrides: [matchingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      matchingControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(matchingControllerProvider.notifier);
    final intentSubscription = container.listen(
      breedingIntentProvider('match-1'),
      (_, _) {},
    );
    addTearDown(intentSubscription.close);
    expect(
      await container.read(breedingIntentProvider('match-1').future),
      isNull,
    );

    await controller.rejectRequest('request-1');
    await controller.cancelRequest('request-1');
    await controller.proposeBreedingIntent('match-1', notes: 'Futura camada');
    expect(
      (await container.read(breedingIntentProvider('match-1').future))?.status,
      'Proposed',
    );
    await controller.acceptBreedingIntent('match-1', 'intent-1');
    expect(
      (await container.read(breedingIntentProvider('match-1').future))?.status,
      'Agreed',
    );
    await controller.cancelBreedingIntent('match-1', 'intent-1');
    expect(
      (await container.read(breedingIntentProvider('match-1').future))?.status,
      'Cancelled',
    );

    expect(
      repository.calls,
      containsAll(['propose', 'acceptIntent', 'cancelIntent']),
    );
    expect(repository.calls.where((call) => call == 'getMatch').length, 4);
    expect(repository.calls.where((call) => call == 'getIntent').length, 3);
  });
}
