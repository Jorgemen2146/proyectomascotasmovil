import 'dart:typed_data';

import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/services/photo_picker_service.dart';
import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

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

  test('selector acepta una imagen válida y limita a 10 MB', () {
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
      'La imagen es demasiado grande. El tamaño máximo permitido es 10 MB.',
    );
  });

  test('rechaza bytes mayores a 10 MB antes de generar Base64', () async {
    final oversizedBytes = Uint8List(
      ImagePickerPhotoPickerService.maxBytes + 1,
    );
    final photo = SelectedPhoto(
      file: XFile.fromData(oversizedBytes, name: 'grande.jpg'),
      fileName: 'grande.jpg',
      contentType: 'image/jpeg',
      fileSize: oversizedBytes.length,
    );

    await expectLater(
      preparePhotoUpload(photo),
      throwsA(
        isA<PhotoValidationException>().having(
          (error) => error.message,
          'message',
          'La imagen es demasiado grande. '
              'El tamaño máximo permitido es 10 MB.',
        ),
      ),
    );
  });

  test('preparación genera Base64 puro y MIME desde la extensión', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final prepared = await preparePhotoUpload(
      SelectedPhoto(
        file: XFile.fromData(bytes, name: 'dog.jpeg'),
        fileName: 'dog.jpeg',
        contentType: 'application/octet-stream',
        fileSize: bytes.length,
      ),
    );

    expect(prepared.imageBase64, 'AQIDBA==');
    expect(prepared.imageBase64, isNot(startsWith('data:')));
    expect(prepared.contentType, 'image/jpeg');
  });

  test('crear mascota y foto completa ambas operaciones', () async {
    final repository = FakePetsRepository();
    final container = ProviderContainer(
      overrides: [petsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(myPetsProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(myPetsProvider.future);
    repository.events.clear();

    final result = await container
        .read(petFormControllerProvider.notifier)
        .createWithOptionalPhoto(_draft, _photo);
    await container.read(myPetsProvider.future);

    expect(result.valueOrNull?.petId, 'pet-created');
    expect(result.valueOrNull?.photoFailure, isNull);
    expect(repository.createCalls, 1);
    expect(repository.uploadCalls, 1);
    expect(repository.events, ['createPet', 'uploadPhoto', 'getMyPets']);
  });

  test('si falla foto conserva mascota creada y expone el error', () async {
    final repository = FakePetsRepository()
      ..uploadFailure = const ServerFailure('photo failed', statusCode: 500);
    final container = ProviderContainer(
      overrides: [petsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(petFormControllerProvider.notifier)
        .createWithOptionalPhoto(_draft, _photo);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.petId, 'pet-created');
    expect(result.valueOrNull?.photoFailure?.message, 'photo failed');
    expect(repository.createCalls, 1);
    expect(repository.uploadCalls, 1);
    expect(repository.deleteCalls, 0);
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

  test('galería sube y elimina foto mediante su controller', () async {
    final repository = FakePetsRepository();
    final container = ProviderContainer(
      overrides: [petsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final uploaded = await container
        .read(petPhotoControllerProvider.notifier)
        .upload('pet-1', _photo);
    final deleted = await container
        .read(petPhotoControllerProvider.notifier)
        .delete('pet-1', 'photo-1');

    expect(uploaded.isSuccess, isTrue);
    expect(deleted.isSuccess, isTrue);
    expect(repository.uploadCalls, 1);
    expect(repository.deletePhotoCalls, 1);
  });
}

final _draft = PetDraft(
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

final _photoBytes = Uint8List.fromList([1, 2, 3]);
final _photo = SelectedPhoto(
  file: XFile.fromData(_photoBytes, name: 'luna.jpg'),
  fileName: 'luna.jpg',
  contentType: 'image/jpeg',
  fileSize: _photoBytes.length,
);
