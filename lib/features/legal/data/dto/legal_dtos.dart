import '../../domain/entities/legal.dart';

class LegalDocumentDto {
  const LegalDocumentDto({
    required this.legalDocumentId,
    required this.type,
    required this.version,
    required this.title,
    required this.content,
    required this.publishedAtUtc,
    required this.effectiveAtUtc,
    required this.requiresAcceptance,
  });

  factory LegalDocumentDto.fromJson(Map<String, dynamic> json) =>
      LegalDocumentDto(
        legalDocumentId: json['legalDocumentId'] as String,
        type: json['type'] as String,
        version: json['version'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        publishedAtUtc: DateTime.parse(json['publishedAtUtc'] as String),
        effectiveAtUtc: DateTime.parse(json['effectiveAtUtc'] as String),
        requiresAcceptance: json['requiresAcceptance'] as bool,
      );

  final String legalDocumentId;
  final String type;
  final String version;
  final String title;
  final String content;
  final DateTime publishedAtUtc;
  final DateTime effectiveAtUtc;
  final bool requiresAcceptance;

  LegalDocument toDomain() => LegalDocument(
    legalDocumentId: legalDocumentId,
    type: type,
    version: version,
    title: title,
    content: content,
    publishedAtUtc: publishedAtUtc,
    effectiveAtUtc: effectiveAtUtc,
    requiresAcceptance: requiresAcceptance,
  );
}

class LegalStatusDto {
  const LegalStatusDto({
    required this.isUpToDate,
    required this.pendingDocuments,
  });

  factory LegalStatusDto.fromJson(Map<String, dynamic> json) => LegalStatusDto(
    isUpToDate: json['isUpToDate'] as bool,
    pendingDocuments: (json['pendingDocuments'] as List<dynamic>? ?? const [])
        .map((item) => LegalDocumentDto.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  final bool isUpToDate;
  final List<LegalDocumentDto> pendingDocuments;

  LegalStatus toDomain() => LegalStatus(
    isUpToDate: isUpToDate,
    pendingDocuments: pendingDocuments
        .map((document) => document.toDomain())
        .toList(growable: false),
  );
}

class LegalConsentHistoryDto {
  const LegalConsentHistoryDto({
    required this.type,
    required this.version,
    required this.acceptedAtUtc,
    this.revokedAtUtc,
  });

  factory LegalConsentHistoryDto.fromJson(Map<String, dynamic> json) =>
      LegalConsentHistoryDto(
        type: json['type'] as String,
        version: json['version'] as String,
        acceptedAtUtc: DateTime.parse(json['acceptedAtUtc'] as String),
        revokedAtUtc: json['revokedAtUtc'] == null
            ? null
            : DateTime.parse(json['revokedAtUtc'] as String),
      );

  final String type;
  final String version;
  final DateTime acceptedAtUtc;
  final DateTime? revokedAtUtc;

  LegalConsentHistory toDomain() => LegalConsentHistory(
    type: type,
    version: version,
    acceptedAtUtc: acceptedAtUtc,
    revokedAtUtc: revokedAtUtc,
  );
}
