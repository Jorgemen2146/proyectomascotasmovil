import 'package:dio/dio.dart';
import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/features/health/data/datasources/health_remote_data_source.dart';
import 'package:dogplatform/features/health/data/repositories/health_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository entrega catálogo mapeado en success', () async {
    final dio = _dioResolving([
      {
        'vaccineId': 1,
        'speciesId': 1,
        'name': 'Rabia',
        'description': 'Anual',
        'isCore': true,
      },
    ]);
    final repository = HealthRepositoryImpl(HealthRemoteDataSource(dio: dio));

    final result = await repository.getVaccines(1);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.single.name, 'Rabia');
  });

  test('repository traduce VACCINE_SPECIES_MISMATCH', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.reject(
          DioException(
            requestOptions: request,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 400,
              data: {
                'code': 'VACCINE_SPECIES_MISMATCH',
                'description': 'backend message',
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    final repository = HealthRepositoryImpl(HealthRemoteDataSource(dio: dio));

    final result = await repository.getVaccines(1);

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(
      result.failureOrNull!.message,
      'Esta vacuna no corresponde a la especie de la mascota.',
    );
  });

  test('repository traduce pet 404 con mensaje útil', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.reject(
          DioException(
            requestOptions: request,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 404,
              data: {'code': 'Vaccination.PetNotFound'},
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    final repository = HealthRepositoryImpl(HealthRemoteDataSource(dio: dio));

    final result = await repository.getPetVaccinations('pet-1');

    expect(result.failureOrNull!.message, 'No se encontró la mascota.');
    expect((result.failureOrNull as ServerFailure).statusCode, 404);
  });
}

Dio _dioResolving(dynamic data) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) => handler.resolve(
        Response<dynamic>(requestOptions: request, statusCode: 200, data: data),
      ),
    ),
  );
  return dio;
}
