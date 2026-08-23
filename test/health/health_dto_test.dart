import 'package:dogplatform/features/health/data/dto/health_dtos.dart';
import 'package:dogplatform/features/health/domain/entities/health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VaccineDto parsea el contrato del catálogo', () {
    final dto = VaccineDto.fromJson({
      'vaccineId': 1,
      'speciesId': 2,
      'name': 'Triple felina',
      'description': null,
      'isCore': true,
    });

    expect(dto.vaccineId, 1);
    expect(dto.speciesId, 2);
    expect(dto.name, 'Triple felina');
    expect(dto.description, isNull);
    expect(dto.isCore, isTrue);
  });

  test('PetVaccinationDto conserva nullables, UTC y estado del backend', () {
    final dto = PetVaccinationDto.fromJson({
      'petVaccinationId': 'vaccination-1',
      'petId': 'pet-1',
      'vaccineId': 3,
      'vaccineName': 'Rabia',
      'doseNumber': null,
      'appliedAtUtc': '2026-08-22T10:00:00Z',
      'nextDueAtUtc': null,
      'status': 'UpToDate',
      'daysRemaining': null,
      'daysOverdue': null,
      'veterinarianName': null,
      'clinicName': 'Veterinaria Central',
      'batchNumber': null,
      'notes': null,
    });

    expect(dto.doseNumber, isNull);
    expect(dto.appliedAtUtc, DateTime.utc(2026, 8, 22, 10));
    expect(dto.nextDueAtUtc, isNull);
    expect(dto.status, 'UpToDate');
    expect(dto.clinicName, 'Veterinaria Central');
  });

  test('requests de create y update usan campos diferentes', () {
    final draft = _draft(vaccineId: 9);

    final create = CreateVaccinationRequestDto(draft).toJson();
    final update = UpdateVaccinationRequestDto(draft).toJson();

    expect(create['vaccineId'], 9);
    expect(create.keys, contains('notes'));
    expect(update.containsKey('vaccineId'), isFalse);
    expect(update['appliedAtUtc'], '2026-08-22T10:00:00.000Z');
  });
}

VaccinationDraft _draft({required int vaccineId}) => VaccinationDraft(
  vaccineId: vaccineId,
  doseNumber: 1,
  appliedAtUtc: DateTime.utc(2026, 8, 22, 10),
  veterinarianName: 'Dra. Pérez',
  clinicName: null,
  batchNumber: 'ABC123',
  notes: null,
);
