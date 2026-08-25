class AppNotification {
  const AppNotification({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.isRead,
    required this.createdAtUtc,
    this.petId,
    this.vaccineId,
    this.readAtUtc,
    this.metadataJson,
    this.metadata,
  });

  final String notificationId;
  final String type;
  final String title;
  final String message;
  final String? petId;
  final int? vaccineId;
  final String status;
  final bool isRead;
  final DateTime? readAtUtc;
  final DateTime createdAtUtc;
  final String? metadataJson;
  final NotificationMetadata? metadata;

  bool get isVaccination => type.startsWith('Vaccination');

  AppNotification copyWith({bool? isRead, DateTime? readAtUtc}) =>
      AppNotification(
        notificationId: notificationId,
        type: type,
        title: title,
        message: message,
        petId: petId,
        vaccineId: vaccineId,
        status: status,
        isRead: isRead ?? this.isRead,
        readAtUtc: readAtUtc ?? this.readAtUtc,
        createdAtUtc: createdAtUtc,
        metadataJson: metadataJson,
        metadata: metadata,
      );
}

class NotificationMetadata {
  const NotificationMetadata({
    this.petName,
    this.vaccineName,
    this.recommendedDueAtUtc,
    this.nextDueAtUtc,
    this.daysRemaining,
    this.daysOverdue,
  });

  final String? petName;
  final String? vaccineName;
  final DateTime? recommendedDueAtUtc;
  final DateTime? nextDueAtUtc;
  final int? daysRemaining;
  final int? daysOverdue;
}

class NotificationPageResult {
  const NotificationPageResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  final List<AppNotification> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  bool get hasMore => pageNumber * pageSize < totalCount;
}
