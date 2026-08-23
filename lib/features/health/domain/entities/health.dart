class Vaccine {
  const Vaccine({
    required this.vaccineId,
    required this.speciesId,
    required this.name,
    required this.isCore,
    this.description,
  });

  final int vaccineId;
  final int speciesId;
  final String name;
  final String? description;
  final bool isCore;
}

class PetVaccination {
  const PetVaccination({
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
}

class VaccinationSummary {
  const VaccinationSummary({
    required this.upToDate,
    required this.dueSoon,
    required this.dueToday,
    required this.overdue,
    required this.notStarted,
  });

  final int upToDate;
  final int dueSoon;
  final int dueToday;
  final int overdue;
  final int notStarted;
}

class VaccinationStatusResult {
  const VaccinationStatusResult({
    required this.petId,
    required this.summary,
    required this.vaccines,
  });

  final String petId;
  final VaccinationSummary summary;
  final List<PetVaccination> vaccines;
}

class VaccinationDraft {
  const VaccinationDraft({
    required this.doseNumber,
    required this.appliedAtUtc,
    this.vaccineId,
    this.veterinarianName,
    this.clinicName,
    this.batchNumber,
    this.notes,
  });

  final int? vaccineId;
  final int? doseNumber;
  final DateTime appliedAtUtc;
  final String? veterinarianName;
  final String? clinicName;
  final String? batchNumber;
  final String? notes;
}
