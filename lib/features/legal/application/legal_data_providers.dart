import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/result/result.dart';
import '../data/datasources/legal_remote_data_source.dart';
import '../data/repositories/legal_repository_impl.dart';
import '../domain/entities/legal.dart';
import '../domain/repositories/legal_repository.dart';

final legalRemoteDataSourceProvider = Provider<LegalRemoteDataSource>((ref) {
  return LegalRemoteDataSource(
    authenticatedDio: ref.read(gatewayDioProvider),
    rawDio: ref.read(gatewayRawDioProvider),
  );
});

final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  return LegalRepositoryImpl(ref.read(legalRemoteDataSourceProvider));
});

final legalDocumentsProvider = FutureProvider<List<LegalDocument>>((ref) async {
  return _unwrap(await ref.read(legalRepositoryProvider).getActiveDocuments());
});

final legalStatusProvider = FutureProvider.autoDispose<LegalStatus>((
  ref,
) async {
  return _unwrap(await ref.read(legalRepositoryProvider).getStatus());
});

final legalConsentsProvider =
    FutureProvider.autoDispose<List<LegalConsentHistory>>((ref) async {
      return _unwrap(await ref.read(legalRepositoryProvider).getConsents());
    });

class LegalController extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false;

  Future<Result<void>> acceptDocument(String legalDocumentId) async {
    if (state) {
      return const Result.failure(
        ValidationFailure('Hay una operación en curso.'),
      );
    }
    state = true;
    final result = await ref
        .read(legalRepositoryProvider)
        .acceptDocument(legalDocumentId);
    state = false;
    if (result.isSuccess) {
      ref.invalidate(legalStatusProvider);
      ref.invalidate(legalConsentsProvider);
    }
    return result;
  }
}

final legalControllerProvider =
    AutoDisposeNotifierProvider<LegalController, bool>(LegalController.new);

void clearUserLegalState(Ref ref) {
  ref.invalidate(legalStatusProvider);
  ref.invalidate(legalConsentsProvider);
  ref.invalidate(legalControllerProvider);
}

T _unwrap<T>(Result<T> result) =>
    result.when(success: (value) => value, failure: (failure) => throw failure);
