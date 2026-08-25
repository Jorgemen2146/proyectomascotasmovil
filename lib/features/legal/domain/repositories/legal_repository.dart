import '../../../../core/result/result.dart';
import '../entities/legal.dart';

abstract class LegalRepository {
  Future<Result<List<LegalDocument>>> getActiveDocuments();
  Future<Result<LegalStatus>> getStatus();
  Future<Result<List<LegalConsentHistory>>> getConsents();
  Future<Result<void>> acceptDocument(String legalDocumentId);
}
