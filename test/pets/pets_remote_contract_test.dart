import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/core/constants/api_paths.dart';
import 'package:dogplatform/core/services/photo_picker_service.dart';
import 'package:dogplatform/features/pets/data/datasources/pets_remote_data_source.dart';
import 'package:dogplatform/features/pets/data/repositories/pets_repository_impl.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  setUpAll(() => AppConfig.init(environment: Environment.dev));

  test('carga species y breeds con paths y respuestas exactas', () async {
    final gateway = _RecordingDio((request) {
      if (request.path == ApiPaths.species) {
        return [
          {'speciesId': 1, 'name': 'Perro'},
        ];
      }
      return [
        {'breedId': 10, 'speciesId': 1, 'name': 'Golden Retriever'},
      ];
    });
    final source = PetsRemoteDataSource(dio: gateway.dio);

    final species = await source.getSpecies();
    final breeds = await source.getBreeds(1);

    expect(species.single.speciesId, 1);
    expect(breeds.single.breedId, 10);
    expect(gateway.requests[0].path, '/api/v1/species');
    expect(gateway.requests[1].path, '/api/v1/species/1/breeds');
  });

  test('crear y editar mascota serializan contratos distintos', () async {
    final gateway = _RecordingDio((request) {
      if (request.method == 'POST') return {'petId': 'pet-1', 'name': 'Luna'};
      return {'petId': 'pet-1', 'name': 'Luna editada'};
    });
    final source = PetsRemoteDataSource(dio: gateway.dio);
    final draft = PetDraft(
      breedId: 10,
      name: 'Luna',
      birthDate: DateTime.utc(2022, 3, 15),
      gender: 'F',
      weight: 25,
      color: 'Dorado',
      pedigreeNumber: null,
      isSterilized: true,
      description: 'Muy cariñosa',
    );

    expect(await source.createPet(draft), 'pet-1');
    await source.updatePet('pet-1', draft);

    final createBody = gateway.requests[0].data as Map;
    expect(createBody['breedId'], 10);
    expect(createBody['gender'], 'F');
    expect(
      createBody.keys,
      containsAll(<String>[
        'breedId',
        'name',
        'birthDate',
        'gender',
        'weight',
        'color',
        'pedigreeNumber',
        'isSterilized',
        'description',
      ]),
    );
    final updateBody = gateway.requests[1].data as Map;
    expect(updateBody.containsKey('breedId'), isFalse);
    expect(gateway.requests[1].method, 'PUT');
  });

  test(
    'upload S3 ejecuta upload-url, bytes externos sin Gateway y confirm',
    () async {
      final gateway = _RecordingDio((request) {
        if (request.path.endsWith('/upload-url')) {
          return {
            'objectKey': 'pets/pet-1/luna.jpg',
            'uploadUrl': 'https://storage.example.test/upload',
            'expiresAtUtc': '2030-01-01T00:00:00Z',
            'requiredHeaders': {'x-storage-header': 'value'},
            'method': 'PUT',
          };
        }
        return {
          'photoId': 'photo-1',
          'petId': 'pet-1',
          'url': '/photos/luna.jpg',
          'isMain': true,
          'createdAt': '2026-01-01T00:00:00Z',
        };
      });
      final upload = _RecordingDio((_) => null);
      final repository = PetsRepositoryImpl(
        PetsRemoteDataSource(dio: gateway.dio, uploadDio: upload.dio),
      );
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final photo = SelectedPhoto(
        file: XFile.fromData(bytes, name: 'luna.jpg', mimeType: 'image/jpeg'),
        fileName: 'luna.jpg',
        contentType: 'image/jpeg',
        fileSize: bytes.length,
      );

      final result = await repository.uploadPhoto('pet-1', photo);

      expect(result.isSuccess, isTrue);
      expect(gateway.requests[0].path, ApiPaths.photoUploadUrl('pet-1'));
      expect(gateway.requests[0].data, {
        'fileName': 'luna.jpg',
        'contentType': 'image/jpeg',
        'fileSize': 4,
      });
      expect(
        upload.requests.single.uri.toString(),
        'https://storage.example.test/upload',
      );
      expect(upload.requests.single.method, 'PUT');
      expect(upload.requests.single.data, isA<Uint8List>());
      expect(upload.requests.single.headers['x-storage-header'], 'value');
      expect(
        upload.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
      expect(gateway.requests[1].path, ApiPaths.confirmPhoto('pet-1'));
      expect(gateway.requests[1].data, {'objectKey': 'pets/pet-1/luna.jpg'});
    },
  );

  test('upload Local usa Gateway autenticado y adapta localhost', () async {
    AppConfig.init(
      environment: Environment.dev,
      apiBaseUrl: 'http://10.0.2.2:5101',
    );
    final gateway = _RecordingDio((request) {
      if (request.path.endsWith('/upload-url')) {
        return {
          'objectKey': 'pets/user-1/pet-1/2026/08/photo.jpg',
          'uploadUrl':
              'http://localhost:5101/api/v1/pets/pet-1/photos/upload/token',
          'method': 'PUT',
          'expiresAtUtc': '2030-01-01T00:00:00Z',
          'requiredHeaders': {'Content-Type': 'image/jpeg'},
        };
      }
      return null;
    });
    final externalStorage = _RecordingDio((_) => null);
    final source = PetsRemoteDataSource(
      dio: gateway.dio,
      uploadDio: externalStorage.dio,
    );
    final ticket = (await source.createPhotoUploadUrl(
      petId: 'pet-1',
      fileName: 'luna.jpg',
      contentType: 'image/jpeg',
      fileSize: 4,
    )).toDomain();

    await source.uploadBytes(
      ticket: ticket,
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      contentType: 'image/jpeg',
    );

    expect(externalStorage.requests, isEmpty);
    expect(gateway.requests[1].method, 'PUT');
    expect(
      gateway.requests[1].uri.toString(),
      'http://10.0.2.2:5101/api/v1/pets/pet-1/photos/upload/token',
    );
    expect(gateway.requests[1].headers['Content-Type'], 'image/jpeg');
  });

  test('galería, principal y eliminar foto usan contratos exactos', () async {
    final gateway = _RecordingDio((request) {
      if (request.method == 'GET') {
        return [
          {
            'photoId': 'photo-1',
            'petId': 'pet-1',
            'url': '/photos/luna.jpg',
            'isMain': true,
            'createdAt': '2026-01-01T00:00:00Z',
          },
        ];
      }
      return null;
    });
    final source = PetsRemoteDataSource(dio: gateway.dio);

    final photos = await source.getPhotos('pet-1');
    await source.setMainPhoto('pet-1', 'photo-1');
    await source.deletePhoto('pet-1', 'photo-1');

    expect(photos.single.photoId, 'photo-1');
    expect(gateway.requests[0].path, '/api/v1/pets/pet-1/photos');
    expect(gateway.requests[1].method, 'PUT');
    expect(gateway.requests[1].path, '/api/v1/pets/pet-1/photos/photo-1/main');
    expect(gateway.requests[1].data, isNull);
    expect(gateway.requests[2].method, 'DELETE');
    expect(gateway.requests[2].path, '/api/v1/pets/pet-1/photos/photo-1');
  });
}

class _RecordingDio {
  _RecordingDio(this.responseFor) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(
            Response<dynamic>(
              requestOptions: request,
              statusCode: 200,
              data: responseFor(request),
            ),
          );
        },
      ),
    );
  }

  final dynamic Function(RequestOptions request) responseFor;
  final Dio dio = Dio();
  final List<RequestOptions> requests = [];
}
