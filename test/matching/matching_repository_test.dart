import 'package:dio/dio.dart';
import 'package:dogplatform/features/matching/data/datasources/matching_remote_data_source.dart';
import 'package:dogplatform/features/matching/data/repositories/matching_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final testCase in [
    ('MATCHING_REQUEST_EXISTS', 'Ya enviaste una solicitud.'),
    (
      'MATCHING_SELF_REQUEST',
      'No puedes enviar una solicitud a tu propia mascota.',
    ),
    (
      'MATCHING_NOT_COMPATIBLE',
      'Estas mascotas no cumplen los criterios actuales.',
    ),
    (
      'MATCHING_CONTACT_NOT_SHARED',
      'El propietario decidió no compartir este dato.',
    ),
    (
      'MATCHING_BREEDING_INTENT_EXISTS',
      'Ya existe una intención activa para esta conexión.',
    ),
    ('MATCHING_FORBIDDEN', 'No tienes permiso para realizar esta acción.'),
  ]) {
    test('mapea ${testCase.$1}', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) => handler.reject(
            DioException(
              requestOptions: request,
              response: Response<dynamic>(
                requestOptions: request,
                statusCode: 409,
                data: {'code': testCase.$1},
              ),
            ),
          ),
        ),
      );
      final repository = MatchingRepositoryImpl(MatchingRemoteDataSource(dio));
      final result = await repository.sendRequest(
        petId: 'mine',
        candidatePetId: 'candidate',
      );
      expect(result.failureOrNull?.message, testCase.$2);
    });
  }
}
