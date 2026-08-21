import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dogplatform/core/config/app_config.dart';
import 'package:dogplatform/core/config/environment.dart';
import 'package:dogplatform/core/constants/api_paths.dart';
import 'package:dogplatform/core/errors/app_failure.dart';
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

  test('foto se convierte a Base64 y usa un único POST JSON', () async {
    final gateway = _RecordingDio((request) => null, statusCode: 201);
    final repository = PetsRepositoryImpl(
      PetsRemoteDataSource(dio: gateway.dio),
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
    expect(gateway.requests, hasLength(1));
    expect(gateway.requests.single.method, 'POST');
    expect(gateway.requests.single.path, ApiPaths.petPhotos('pet-1'));
    expect(gateway.requests.single.data, {
      'fileName': 'luna.jpg',
      'contentType': 'image/jpeg',
      'imageBase64': 'AQIDBA==',
    });
  });

  test('error 500 de foto conserva y muestra errorId', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.reject(
          DioException(
            requestOptions: request,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 500,
              data: {'errorId': 'PHOTO-500-ABC'},
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    final repository = PetsRepositoryImpl(PetsRemoteDataSource(dio: dio));
    final bytes = Uint8List.fromList([1]);

    final result = await repository.uploadPhoto(
      'pet-1',
      SelectedPhoto(
        file: XFile.fromData(bytes, name: 'luna.png'),
        fileName: 'luna.png',
        contentType: 'image/png',
        fileSize: bytes.length,
      ),
    );

    expect(
      result.failureOrNull?.message,
      'Hubo un problema al guardar la foto. Código: PHOTO-500-ABC',
    );
    expect((result.failureOrNull as ServerFailure).errorCode, 'PHOTO-500-ABC');
  });

  test('galería, principal y eliminar foto usan contratos exactos', () async {
    final gateway = _RecordingDio((request) {
      if (request.method == 'GET') {
        return [
          {
            'photoId': 'photo-1',
            'petId': 'pet-1',
            'url': '/photos/luna.jpg',
            'isPrimary': true,
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
    expect(photos.single.isMain, isTrue);
    expect(gateway.requests[0].path, '/api/v1/pets/pet-1/photos');
    expect(gateway.requests[1].method, 'PUT');
    expect(gateway.requests[1].path, '/api/v1/pets/pet-1/photos/photo-1/main');
    expect(gateway.requests[1].data, isNull);
    expect(gateway.requests[2].method, 'DELETE');
    expect(gateway.requests[2].path, '/api/v1/pets/pet-1/photos/photo-1');
  });
}

class _RecordingDio {
  _RecordingDio(this.responseFor, {this.statusCode = 200}) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(
            Response<dynamic>(
              requestOptions: request,
              statusCode: statusCode,
              data: responseFor(request),
            ),
          );
        },
      ),
    );
  }

  final dynamic Function(RequestOptions request) responseFor;
  final int statusCode;
  final Dio dio = Dio();
  final List<RequestOptions> requests = [];
}
