import 'package:dogplatform/core/services/photo_picker_service.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_pets_repository.dart';

void main() {
  test('providers cargan species y breeds', () async {
    final repository = FakePetsRepository()
      ..species = const [Species(speciesId: 1, name: 'Perro')]
      ..breeds[1] = const [
        Breed(breedId: 10, speciesId: 1, name: 'Golden Retriever'),
      ];
    final container = ProviderContainer(
      overrides: [petsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect((await container.read(speciesProvider.future)).single.name, 'Perro');
    expect(
      (await container.read(breedsProvider(1).future)).single.name,
      'Golden Retriever',
    );
  });

  test('controller crea y edita mascota', () async {
    final repository = FakePetsRepository();
    final container = ProviderContainer(
      overrides: [petsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final draft = PetDraft(
      breedId: 10,
      name: 'Luna',
      birthDate: DateTime.utc(2022),
      gender: 'F',
      weight: 25,
      color: 'Dorado',
      pedigreeNumber: null,
      isSterilized: true,
      description: null,
    );

    final created = await container
        .read(petFormControllerProvider.notifier)
        .create(draft);
    final updated = await container
        .read(petFormControllerProvider.notifier)
        .update('pet-1', draft);

    expect(created.valueOrNull, 'pet-created');
    expect(updated.isSuccess, isTrue);
    expect(repository.createCalls, 1);
    expect(repository.updateCalls, 1);
  });

  test('selector valida formato y máximo de 5 MB', () {
    expect(ImagePickerPhotoPickerService.validatePhoto('dog.jpg', 100), isNull);
    expect(
      ImagePickerPhotoPickerService.validatePhoto('dog.webp', 100),
      isNull,
    );
    expect(
      ImagePickerPhotoPickerService.validatePhoto('dog.gif', 100),
      contains('JPG'),
    );
    expect(
      ImagePickerPhotoPickerService.validatePhoto(
        'dog.png',
        ImagePickerPhotoPickerService.maxBytes + 1,
      ),
      contains('5 MB'),
    );
  });

  test('controller establece foto principal', () async {
    final repository = FakePetsRepository();
    final container = ProviderContainer(
      overrides: [petsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(petPhotoControllerProvider.notifier)
        .setMain('pet-1', 'photo-1');

    expect(result.isSuccess, isTrue);
    expect(repository.setMainPhotoCalls, 1);
  });
}
