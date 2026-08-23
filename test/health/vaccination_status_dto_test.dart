import 'package:dogplatform/features/health/data/dto/health_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VaccinationStatusDto usa resumen y vacunas entregados por backend', () {
    final dto = VaccinationStatusDto.fromJson({
      'petId': 'pet-1',
      'summary': {
        'upToDate': 3,
        'dueSoon': 1,
        'dueToday': 1,
        'overdue': 2,
        'notStarted': 4,
      },
      'vaccines': [
        {
          'petVaccinationId': '00000000-0000-0000-0000-000000000000',
          'petId': 'pet-1',
          'vaccineId': 5,
          'vaccineName': 'Rabia',
          'doseNumber': null,
          'appliedAtUtc': null,
          'nextDueAtUtc': '2026-09-01T00:00:00Z',
          'status': 'NotStarted',
          'daysRemaining': null,
          'daysOverdue': 0,
          'veterinarianName': null,
          'clinicName': null,
          'batchNumber': null,
          'notes': null,
          'eligible': false,
          'recommendedDueAtUtc': '2026-09-09T00:00:00Z',
          'daysUntilEligible': 18,
        },
      ],
    });
    final result = dto.toDomain();

    expect(result.petId, 'pet-1');
    expect(result.summary.upToDate, 3);
    expect(result.summary.dueSoon, 1);
    expect(result.summary.dueToday, 1);
    expect(result.summary.overdue, 2);
    expect(result.summary.notStarted, 4);
    expect(result.vaccines.single.status, 'NotStarted');
    expect(result.vaccines.single.appliedAtUtc, isNull);
    expect(result.vaccines.single.eligible, isFalse);
    expect(
      result.vaccines.single.recommendedDueAtUtc,
      DateTime.utc(2026, 9, 9),
    );
    expect(result.vaccines.single.daysUntilEligible, 18);
  });
}
