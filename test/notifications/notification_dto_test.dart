import 'package:dogplatform/features/notifications/data/dto/notification_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea respuesta real, metadata y tipos de vacunación', () {
    const types = [
      'VaccinationDueSoon',
      'VaccinationDueToday',
      'VaccinationOverdue',
      'VaccinationNotStarted',
    ];

    for (final type in types) {
      final dto = NotificationDto.fromJson({
        'notificationId': 'notification-$type',
        'type': type,
        'title': 'Vacuna',
        'message': 'Mensaje',
        'petId': 'pet-1',
        'vaccineId': 7,
        'status': 'Pending',
        'isRead': false,
        'readAtUtc': null,
        'createdAtUtc': '2026-08-23T10:00:00Z',
        'metadataJson':
            '{"PetName":"Luna","VaccineName":"Rabia",'
            '"DaysRemaining":3}',
      });
      final item = dto.toDomain();

      expect(item.type, type);
      expect(item.isVaccination, isTrue);
      expect(item.petId, 'pet-1');
      expect(item.metadata?.petName, 'Luna');
      expect(item.metadata?.daysRemaining, 3);
    }
  });

  test('parsea página y unread count sin asumir listas planas', () {
    final page = NotificationPageDto.fromJson({
      'items': <dynamic>[],
      'pageNumber': 1,
      'pageSize': 20,
      'totalCount': 0,
    }).toDomain();
    final count = UnreadCountDto.fromJson({'count': 9});

    expect(page.items, isEmpty);
    expect(page.pageNumber, 1);
    expect(page.hasMore, isFalse);
    expect(count.count, 9);
  });

  test('parsea IDs Matching solo desde metadata backend', () {
    final item = NotificationDto.fromJson({
      'notificationId': 'matching-1',
      'type': 'MatchingRequestAccepted',
      'title': 'Match',
      'message': 'Solicitud aceptada',
      'petId': 'pet-1',
      'vaccineId': null,
      'status': 'Pending',
      'isRead': false,
      'readAtUtc': null,
      'createdAtUtc': '2026-08-25T10:00:00Z',
      'metadataJson': '{"MatchRequestId":"request-1","MatchId":"match-1"}',
    }).toDomain();

    expect(item.isMatching, isTrue);
    expect(item.metadata?.matchRequestId, 'request-1');
    expect(item.metadata?.matchId, 'match-1');
  });
}
