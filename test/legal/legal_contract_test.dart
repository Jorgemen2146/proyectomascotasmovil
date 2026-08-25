import 'package:dio/dio.dart';
import 'package:dogplatform/core/constants/api_paths.dart';
import 'package:dogplatform/features/legal/data/datasources/legal_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa endpoints y body exactos de Postman', () async {
    final raw = _RecordingDio()..responseData = [_document];
    final authenticated = _RecordingDio();
    final source = LegalRemoteDataSource(
      authenticatedDio: authenticated.dio,
      rawDio: raw.dio,
    );

    await source.getActiveDocuments();
    expect(raw.lastRequest?.path, ApiPaths.legalDocuments);
    expect(raw.lastRequest?.method, 'GET');

    authenticated.responseData = {
      'isUpToDate': false,
      'pendingDocuments': [_document],
    };
    await source.getStatus();
    expect(authenticated.lastRequest?.path, ApiPaths.legalStatus);

    authenticated.responseData = <dynamic>[];
    await source.getConsents();
    expect(authenticated.lastRequest?.path, ApiPaths.legalConsents);
    expect(authenticated.lastRequest?.method, 'GET');

    await source.acceptDocument('document-id');
    expect(authenticated.lastRequest?.path, ApiPaths.legalConsents);
    expect(authenticated.lastRequest?.method, 'POST');
    expect(authenticated.lastRequest?.data, {'legalDocumentId': 'document-id'});
  });
}

class _RecordingDio {
  _RecordingDio() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          lastRequest = request;
          handler.resolve(
            Response<dynamic>(
              requestOptions: request,
              statusCode: 200,
              data: responseData,
            ),
          );
        },
      ),
    );
  }

  final Dio dio = Dio();
  RequestOptions? lastRequest;
  dynamic responseData;
}

final _document = {
  'legalDocumentId': 'document-id',
  'type': 'TermsAndConditions',
  'version': '2.0',
  'title': 'Términos',
  'content': 'Contenido',
  'publishedAtUtc': '2026-08-20T00:00:00Z',
  'effectiveAtUtc': '2026-08-25T00:00:00Z',
  'requiresAcceptance': true,
};
