import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/network/dio_exception_mapper.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/legal.dart';
import '../../domain/repositories/legal_repository.dart';
import '../datasources/legal_remote_data_source.dart';

class LegalRepositoryImpl implements LegalRepository {
  const LegalRepositoryImpl(this._remote);

  final LegalRemoteDataSource _remote;

  @override
  Future<Result<List<LegalDocument>>> getActiveDocuments() => _run(
    () async => (await _remote.getActiveDocuments())
        .map((document) => document.toDomain())
        .toList(growable: false),
  );

  @override
  Future<Result<LegalStatus>> getStatus() =>
      _run(() async => (await _remote.getStatus()).toDomain());

  @override
  Future<Result<List<LegalConsentHistory>>> getConsents() => _run(
    () async => (await _remote.getConsents())
        .map((consent) => consent.toDomain())
        .toList(growable: false),
  );

  @override
  Future<Result<void>> acceptDocument(String legalDocumentId) async {
    try {
      await _remote.acceptDocument(legalDocumentId);
      return const Result.success(null);
    } on DioException catch (error) {
      if (_errorCode(error) == 'LEGAL_CONSENT_ALREADY_EXISTS') {
        return const Result.success(null);
      }
      return Result.failure(_mapLegalFailure(error));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }

  Future<Result<T>> _run<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on DioException catch (error) {
      return Result.failure(_mapLegalFailure(error));
    } catch (_) {
      return const Result.failure(UnknownFailure());
    }
  }
}

String _errorCode(DioException error) {
  final data = error.response?.data;
  return data is Map
      ? (data['code'] ?? data['errorId'] ?? data['error'] ?? '')
            .toString()
            .toUpperCase()
      : '';
}

AppFailure _mapLegalFailure(DioException error) {
  final message = switch (_errorCode(error)) {
    'LEGAL_CONSENT_REQUIRED' => 'Debes aceptar los documentos requeridos.',
    'LEGAL_DOCUMENT_VERSION_INVALID' =>
      'Los documentos legales se actualizaron. Revísalos nuevamente.',
    'LEGAL_DOCUMENT_NOT_FOUND' => 'No pudimos cargar el documento.',
    _ => null,
  };
  if (message != null) return ValidationFailure(message);
  return mapExceptionToFailure(mapDioExceptionToAppException(error));
}
