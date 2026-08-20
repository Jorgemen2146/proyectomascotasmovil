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
}
