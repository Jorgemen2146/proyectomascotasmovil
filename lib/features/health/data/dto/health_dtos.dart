import '../../domain/entities/health.dart';

class VaccineDto {
  const VaccineDto({
    required this.vaccineId,
    required this.speciesId,
    required this.name,
    required this.isCore,
    this.description,
  });

  factory VaccineDto.fromJson(Map<String, dynamic> json) => VaccineDto(
    vaccineId: json['vaccineId'] as int,
    speciesId: json['speciesId'] as int,
    name: json['name'] as String,
    description: json['description'] as String?,
    isCore: json['isCore'] as bool,
  );

  final int vaccineId;
  final int speciesId;
  final String name;
  final String? description;
  final bool isCore;

  Vaccine toDomain() => Vaccine(
    vaccineId: vaccineId,
    speciesId: speciesId,
    name: name,
    description: description,
    isCore: isCore,
  );
}

class PetVaccinationDto {
  const PetVaccinationDto({
    required this.petVaccinationId,
    required this.petId,
    required this.vaccineId,
    required this.vaccineName,
    required this.status,
    this.doseNumber,
    this.appliedAtUtc,
    this.nextDueAtUtc,
    this.daysRemaining,
    this.daysOverdue,
    this.veterinarianName,
    this.clinicName,
    this.batchNumber,
    this.notes,
    this.eligible,
    this.recommendedDueAtUtc,
    this.daysUntilEligible,
  });

  factory PetVaccinationDto.fromJson(Map<String, dynamic> json) =>
      PetVaccinationDto(
        petVaccinationId: json['petVaccinationId'] as String,
        petId: json['petId'] as String,
        vaccineId: json['vaccineId'] as int,
        vaccineName: json['vaccineName'] as String,
        doseNumber: json['doseNumber'] as int?,
        appliedAtUtc: _date(json['appliedAtUtc']),
        nextDueAtUtc: _date(json['nextDueAtUtc']),
        status: json['status'] as String,
        daysRemaining: json['daysRemaining'] as int?,
        daysOverdue: json['daysOverdue'] as int?,
        veterinarianName: json['veterinarianName'] as String?,
        clinicName: json['clinicName'] as String?,
        batchNumber: json['batchNumber'] as String?,
        notes: json['notes'] as String?,
        eligible: json['eligible'] as bool?,
        recommendedDueAtUtc: _date(json['recommendedDueAtUtc']),
        daysUntilEligible: json['daysUntilEligible'] as int?,
      );

  final String petVaccinationId;
  final String petId;
  final int vaccineId;
  final String vaccineName;
  final int? doseNumber;
  final DateTime? appliedAtUtc;
  final DateTime? nextDueAtUtc;
  final String status;
  final int? daysRemaining;
  final int? daysOverdue;
  final String? veterinarianName;
  final String? clinicName;
  final String? batchNumber;
  final String? notes;
  final bool? eligible;
  final DateTime? recommendedDueAtUtc;
  final int? daysUntilEligible;

  PetVaccination toDomain() => PetVaccination(
    petVaccinationId: petVaccinationId,
    petId: petId,
    vaccineId: vaccineId,
    vaccineName: vaccineName,
    doseNumber: doseNumber,
    appliedAtUtc: appliedAtUtc,
    nextDueAtUtc: nextDueAtUtc,
    status: status,
    daysRemaining: daysRemaining,
    daysOverdue: daysOverdue,
    veterinarianName: veterinarianName,
    clinicName: clinicName,
    batchNumber: batchNumber,
    notes: notes,
    eligible: eligible,
    recommendedDueAtUtc: recommendedDueAtUtc,
    daysUntilEligible: daysUntilEligible,
  );
}

class VaccinationSummaryDto {
  const VaccinationSummaryDto({
    required this.upToDate,
    required this.dueSoon,
    required this.dueToday,
    required this.overdue,
    required this.notStarted,
  });

  factory VaccinationSummaryDto.fromJson(Map<String, dynamic> json) =>
      VaccinationSummaryDto(
        upToDate: json['upToDate'] as int,
        dueSoon: json['dueSoon'] as int,
        dueToday: json['dueToday'] as int,
        overdue: json['overdue'] as int,
        notStarted: json['notStarted'] as int,
      );

  final int upToDate;
  final int dueSoon;
  final int dueToday;
  final int overdue;
  final int notStarted;

  VaccinationSummary toDomain() => VaccinationSummary(
    upToDate: upToDate,
    dueSoon: dueSoon,
    dueToday: dueToday,
    overdue: overdue,
    notStarted: notStarted,
  );
}

class VaccinationStatusDto {
  const VaccinationStatusDto({
    required this.petId,
    required this.summary,
    required this.vaccines,
  });

  factory VaccinationStatusDto.fromJson(Map<String, dynamic> json) =>
      VaccinationStatusDto(
        petId: json['petId'] as String,
        summary: VaccinationSummaryDto.fromJson(
          json['summary'] as Map<String, dynamic>,
        ),
        vaccines: (json['vaccines'] as List<dynamic>)
            .map(
              (item) =>
                  PetVaccinationDto.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  final String petId;
  final VaccinationSummaryDto summary;
  final List<PetVaccinationDto> vaccines;

  VaccinationStatusResult toDomain() => VaccinationStatusResult(
    petId: petId,
    summary: summary.toDomain(),
    vaccines: vaccines.map((item) => item.toDomain()).toList(growable: false),
  );
}

class CreateVaccinationRequestDto {
  const CreateVaccinationRequestDto(this.draft);
  final VaccinationDraft draft;

  Map<String, dynamic> toJson() => {
    'vaccineId': draft.vaccineId,
    'doseNumber': draft.doseNumber,
    'appliedAtUtc': draft.appliedAtUtc.toUtc().toIso8601String(),
    'veterinarianName': draft.veterinarianName,
    'clinicName': draft.clinicName,
    'batchNumber': draft.batchNumber,
    'notes': draft.notes,
  };
}

class UpdateVaccinationRequestDto {
  const UpdateVaccinationRequestDto(this.draft);
  final VaccinationDraft draft;

  Map<String, dynamic> toJson() => {
    'doseNumber': draft.doseNumber,
    'appliedAtUtc': draft.appliedAtUtc.toUtc().toIso8601String(),
    'veterinarianName': draft.veterinarianName,
    'clinicName': draft.clinicName,
    'batchNumber': draft.batchNumber,
    'notes': draft.notes,
  };
}

DateTime? _date(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);
