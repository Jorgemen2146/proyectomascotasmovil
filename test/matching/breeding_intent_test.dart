import 'package:dio/dio.dart';
import 'package:dogplatform/features/matching/data/datasources/matching_remote_data_source.dart';
import 'package:dogplatform/features/matching/data/dto/matching_dtos.dart';
import 'package:dogplatform/features/matching/data/repositories/matching_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parsea el contrato completo de BreedingIntent', () {
    final intent = BreedingIntentDto.fromJson({
      'breedingIntentId': 'intent-1',
      'matchId': 'match-1',
      'status': 'Agreed',
      'notes': 'Futura camada',
      'expectedDateUtc': '2026-11-15T00:00:00Z',
      'createdAtUtc': '2026-08-25T10:00:00Z',
      'acceptedAtUtc': '2026-08-26T10:00:00Z',
      'cancelledAtUtc': null,
      'proposedByCurrentUser': false,
    }).toDomain();

    expect(intent.breedingIntentId, 'intent-1');
    expect(intent.matchId, 'match-1');
    expect(intent.status, 'Agreed');
    expect(intent.notes, 'Futura camada');
    expect(intent.expectedDateUtc, DateTime.utc(2026, 11, 15));
    expect(intent.createdAtUtc, DateTime.utc(2026, 8, 25, 10));
    expect(intent.acceptedAtUtc, DateTime.utc(2026, 8, 26, 10));
    expect(intent.cancelledAtUtc, isNull);
    expect(intent.proposedByCurrentUser, isFalse);
  });

  test('MatchDetail acepta breedingIntent null', () {
    final detail = PetMatchDetailDto.fromJson({
      ..._matchDetail,
      'breedingIntent': null,
    }).toDomain();

    expect(detail.breedingIntent, isNull);
  });

  test('MatchDetail parsea resumen sin exponer ids de propietario', () {
    final detail = PetMatchDetailDto.fromJson({
      ..._matchDetail,
      'breedingIntent': {
        'breedingIntentId': 'intent-1',
        'status': 'Proposed',
        'notes': null,
        'expectedDateUtc': null,
        'createdAtUtc': '2026-08-25T10:00:00Z',
        'proposedByCurrentUser': true,
      },
    }).toDomain();

    expect(detail.breedingIntent?.matchId, 'match-1');
    expect(detail.breedingIntent?.proposedByCurrentUser, isTrue);
    expect(detail.pet1Owner.phoneNumber, isNull);
  });

  test('GET breeding-intent trata 404 como ausencia normal', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.reject(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: request,
              statusCode: 404,
              data: const {'code': 'Matching.BreedingIntentNotFound'},
            ),
          ),
        ),
      ),
    );
    final repository = MatchingRepositoryImpl(MatchingRemoteDataSource(dio));

    final result = await repository.getBreedingIntent('match-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });
}

const _pet = {
  'petId': 'mine',
  'name': 'Andrea',
  'speciesName': 'Gato',
  'breedName': 'Mestizo',
  'sex': 'M',
  'ageMonths': 24,
  'mainPhotoUrl': null,
  'color': null,
};

final _matchDetail = <String, dynamic>{
  'matchId': 'match-1',
  'status': 'Active',
  'pet1': _pet,
  'pet2': {..._pet, 'petId': 'candidate', 'name': 'Luna'},
  'pet1Owner': {'displayName': 'Jorge', 'phoneNumber': null},
  'pet2Owner': {'displayName': 'Ana', 'phoneNumber': null},
  'createdAtUtc': '2026-08-25T00:00:00Z',
};
