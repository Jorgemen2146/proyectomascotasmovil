import 'package:dogplatform/core/result/result.dart';
import 'package:dogplatform/features/legal/domain/entities/legal.dart';
import 'package:dogplatform/features/legal/domain/repositories/legal_repository.dart';

class FakeLegalRepository implements LegalRepository {
  List<LegalDocument> documents = sampleLegalDocuments;
  LegalStatus status = const LegalStatus(
    isUpToDate: true,
    pendingDocuments: [],
  );
  List<LegalConsentHistory> consents = const [];
  Result<List<LegalDocument>>? documentsResult;
  final List<String> acceptedIds = [];
  int statusCalls = 0;

  @override
  Future<Result<List<LegalDocument>>> getActiveDocuments() async =>
      documentsResult ?? Result.success(documents);

  @override
  Future<Result<LegalStatus>> getStatus() async {
    statusCalls++;
    return Result.success(status);
  }

  @override
  Future<Result<List<LegalConsentHistory>>> getConsents() async =>
      Result.success(consents);

  @override
  Future<Result<void>> acceptDocument(String legalDocumentId) async {
    acceptedIds.add(legalDocumentId);
    return const Result.success(null);
  }
}

final sampleLegalDocuments = [
  LegalDocument(
    legalDocumentId: 'terms-id',
    type: 'TermsAndConditions',
    version: '2.4',
    title: 'Términos y Condiciones',
    content: 'Contenido completo de términos.',
    publishedAtUtc: DateTime.utc(2026, 8, 20),
    effectiveAtUtc: DateTime.utc(2026, 8, 25),
    requiresAcceptance: true,
  ),
  LegalDocument(
    legalDocumentId: 'privacy-id',
    type: 'PrivacyPolicy',
    version: '3.1',
    title: 'Política de Privacidad',
    content: 'Contenido completo de privacidad.',
    publishedAtUtc: DateTime.utc(2026, 8, 21),
    effectiveAtUtc: DateTime.utc(2026, 8, 25),
    requiresAcceptance: true,
  ),
];
