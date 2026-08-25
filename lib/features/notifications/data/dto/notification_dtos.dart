import 'dart:convert';

import '../../domain/entities/notification.dart';

class NotificationDto {
  const NotificationDto({
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
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      NotificationDto(
        notificationId: json['notificationId'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        petId: json['petId'] as String?,
        vaccineId: json['vaccineId'] as int?,
        status: json['status'] as String,
        isRead: json['isRead'] as bool,
        readAtUtc: _date(json['readAtUtc']),
        createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
        metadataJson: json['metadataJson'] as String?,
      );

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

  AppNotification toDomain() => AppNotification(
    notificationId: notificationId,
    type: type,
    title: title,
    message: message,
    petId: petId,
    vaccineId: vaccineId,
    status: status,
    isRead: isRead,
    readAtUtc: readAtUtc,
    createdAtUtc: createdAtUtc,
    metadataJson: metadataJson,
    metadata: _metadata(metadataJson),
  );
}

class NotificationPageDto {
  const NotificationPageDto({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory NotificationPageDto.fromJson(Map<String, dynamic> json) =>
      NotificationPageDto(
        items: (json['items'] as List<dynamic>)
            .map(
              (item) => NotificationDto.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
        pageNumber: json['pageNumber'] as int,
        pageSize: json['pageSize'] as int,
        totalCount: json['totalCount'] as int,
      );

  final List<NotificationDto> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  NotificationPageResult toDomain() => NotificationPageResult(
    items: items.map((item) => item.toDomain()).toList(growable: false),
    pageNumber: pageNumber,
    pageSize: pageSize,
    totalCount: totalCount,
  );
}

class UnreadCountDto {
  const UnreadCountDto(this.count);

  factory UnreadCountDto.fromJson(Map<String, dynamic> json) =>
      UnreadCountDto(json['count'] as int);

  final int count;
}

class NotificationRealtimeEnvelopeDto {
  const NotificationRealtimeEnvelopeDto._();

  static AppNotification? tryParse(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic> ||
          decoded['event'] != 'notificationReceived') {
        return null;
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      final notification = NotificationDto.fromJson(data).toDomain();
      return notification.notificationId.trim().isEmpty ? null : notification;
    } on Object {
      return null;
    }
  }
}

NotificationMetadata? _metadata(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic>) return null;
    return NotificationMetadata(
      petName: (json['PetName'] ?? json['petName']) as String?,
      vaccineName: (json['VaccineName'] ?? json['vaccineName']) as String?,
      recommendedDueAtUtc: _date(
        json['RecommendedDueAtUtc'] ?? json['recommendedDueAtUtc'],
      ),
      nextDueAtUtc: _date(json['NextDueAtUtc'] ?? json['nextDueAtUtc']),
      daysRemaining: (json['DaysRemaining'] ?? json['daysRemaining']) as int?,
      daysOverdue: (json['DaysOverdue'] ?? json['daysOverdue']) as int?,
    );
  } on FormatException {
    return null;
  }
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);
