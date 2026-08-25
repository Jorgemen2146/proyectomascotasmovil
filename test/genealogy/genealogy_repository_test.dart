import 'package:dio/dio.dart';
import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/features/genealogy/data/datasources/genealogy_remote_data_source.dart';
import 'package:dogplatform/features/genealogy/data/repositories/genealogy_repository_impl.dart';
import 'package:dogplatform/features/genealogy/domain/entities/genealogy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scenario in {
    'GENEALOGY_CYCLE_DETECTED': 'Esta relación generaría un ciclo en el árbol.',
    'GENEALOGY_PARENT_SEX_MISMATCH':
        'El sexo de la mascota no corresponde al progenitor seleccionado.',
  }.entries) {
    test('mapea ${scenario.key}', () async {
      final repository = _rejectingRepository(scenario.key);
      final result = await repository.addOwnParent(
        childPetId: 'root',
        parentPetId: 'parent',
        role: GenealogyParentRole.father,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, scenario.value);
    });
  }
}

GenealogyRepositoryImpl _rejectingRepository(String errorId) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) => handler.reject(
        DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: 400,
            data: {
              'code': errorId,
              'description': 'Backend error description',
              'type': 'Validation',
            },
          ),
        ),
      ),
    ),
  );
  return GenealogyRepositoryImpl(GenealogyRemoteDataSource(dio: dio));
}
