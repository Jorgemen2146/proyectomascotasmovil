import 'package:dio/dio.dart';

import '../../../../core/constants/api_paths.dart';
import '../dto/legal_dtos.dart';

class LegalRemoteDataSource {
  const LegalRemoteDataSource({
    required Dio authenticatedDio,
    required Dio rawDio,
  }) : this._internal(authenticatedDio, rawDio);

  const LegalRemoteDataSource._internal(this._authenticatedDio, this._rawDio);

  final Dio _authenticatedDio;
  final Dio _rawDio;

  Future<List<LegalDocumentDto>> getActiveDocuments() async {
    final response = await _rawDio.get<List<dynamic>>(ApiPaths.legalDocuments);
    return (response.data ?? const [])
        .map((item) => LegalDocumentDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<LegalStatusDto> getStatus() async {
    final response = await _authenticatedDio.get<Map<String, dynamic>>(
      ApiPaths.legalStatus,
    );
    return LegalStatusDto.fromJson(response.data!);
  }

  Future<List<LegalConsentHistoryDto>> getConsents() async {
    final response = await _authenticatedDio.get<List<dynamic>>(
      ApiPaths.legalConsents,
    );
    return (response.data ?? const [])
        .map(
          (item) =>
              LegalConsentHistoryDto.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<void> acceptDocument(String legalDocumentId) =>
      _authenticatedDio.post<void>(
        ApiPaths.legalConsents,
        data: {'legalDocumentId': legalDocumentId},
      );
}
