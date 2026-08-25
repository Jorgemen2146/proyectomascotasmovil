class LegalDocument {
  const LegalDocument({
    required this.legalDocumentId,
    required this.type,
    required this.version,
    required this.title,
    required this.content,
    required this.publishedAtUtc,
    required this.effectiveAtUtc,
    required this.requiresAcceptance,
  });

  final String legalDocumentId;
  final String type;
  final String version;
  final String title;
  final String content;
  final DateTime publishedAtUtc;
  final DateTime effectiveAtUtc;
  final bool requiresAcceptance;
}

class LegalConsentSelection {
  const LegalConsentSelection({required this.type, required this.version});

  final String type;
  final String version;
}

class LegalStatus {
  const LegalStatus({required this.isUpToDate, required this.pendingDocuments});

  final bool isUpToDate;
  final List<LegalDocument> pendingDocuments;
}

class LegalConsentHistory {
  const LegalConsentHistory({
    required this.type,
    required this.version,
    required this.acceptedAtUtc,
    this.revokedAtUtc,
  });

  final String type;
  final String version;
  final DateTime acceptedAtUtc;
  final DateTime? revokedAtUtc;
}

extension LegalDocumentListX on List<LegalDocument> {
  LegalDocument? byType(String type) {
    for (final document in this) {
      if (document.type.toLowerCase() == type.toLowerCase()) return document;
    }
    return null;
  }
}
