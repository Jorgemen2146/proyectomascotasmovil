import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dogplatform/core/errors/app_failure.dart';
import 'package:dogplatform/core/errors/failure_mapper.dart';
import 'package:dogplatform/core/interceptors/safe_http_log_interceptor.dart';
import 'package:dogplatform/core/network/dio_exception_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mapper prioriza el primer error de validación ASP.NET Core', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/api/v1/auth/register'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/auth/register'),
        statusCode: 400,
        data: {
          'title': 'One or more validation errors occurred.',
          'status': 400,
          'errors': {
            'FirstName': ['The FirstName field is required.'],
          },
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final failure = mapExceptionToFailure(
      mapDioExceptionToAppException(exception),
    );

    expect(failure, isA<ValidationFailure>());
    expect(failure.message, 'The FirstName field is required.');
    expect((failure as ValidationFailure).fieldErrors['FirstName'], [
      'The FirstName field is required.',
    ]);
  });

  test('logging enmascara secretos también en estructuras anidadas', () {
    final sanitized =
        sanitizeHttpValue({
              'email': 'jorge@test.com',
              'password': 'secret',
              'tokens': {'accessToken': 'access', 'refreshToken': 'refresh'},
              'Authorization': 'Bearer token',
            })
            as Map;

    expect(sanitized['email'], 'jorge@test.com');
    expect(sanitized['password'], '***');
    expect((sanitized['tokens'] as Map)['accessToken'], '***');
    expect((sanitized['tokens'] as Map)['refreshToken'], '***');
    expect(sanitized['Authorization'], '***');
  });

  test('logging no imprime los bytes de una imagen', () {
    expect(
      sanitizeHttpValue(Uint8List.fromList([1, 2, 3, 4])),
      '<binary 4 bytes>',
    );
  });

  test('logging reemplaza campos Base64 sin conservar su contenido', () {
    const rawBase64 = 'c2VjcmV0LWltYWdl';
    final sanitized =
        sanitizeHttpValue({
              'imageBase64': rawBase64,
              'nested': {'base64': rawBase64, 'imageData': rawBase64},
            })
            as Map;

    expect(sanitized['imageBase64'], '[BASE64_IMAGE_REMOVED]');
    expect((sanitized['nested'] as Map)['base64'], '[BASE64_IMAGE_REMOVED]');
    expect((sanitized['nested'] as Map)['imageData'], '[BASE64_IMAGE_REMOVED]');
    expect(sanitized.toString(), isNot(contains(rawBase64)));
  });

  test('mapper conserva errorId devuelto por el backend', () {
    final exception = DioException(
      requestOptions: RequestOptions(path: '/api/v1/pets/pet-1/photos'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/v1/pets/pet-1/photos'),
        statusCode: 500,
        data: {'errorId': 'ERR-123'},
      ),
      type: DioExceptionType.badResponse,
    );

    final failure =
        mapExceptionToFailure(mapDioExceptionToAppException(exception))
            as ServerFailure;

    expect(failure.errorCode, 'ERR-123');
  });
}
