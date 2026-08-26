import 'package:dio/dio.dart';
import 'package:dogplatform/features/matching/data/datasources/matching_remote_data_source.dart';
import 'package:dogplatform/features/matching/domain/entities/matching.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa endpoints, filtros y bodies exactos de Matching', () async {
    final recorder = _RecordingDio();
    final source = MatchingRemoteDataSource(recorder.dio);

    await source.getProfile('mine');
    await source.createProfile(
      const MatchingProfileDraft(
        petId: 'mine',
        lookingForSex: 'F',
        allowMixedBreed: true,
        preferredBreedId: 7,
        minimumAgeMonths: 18,
        maximumAgeMonths: 72,
        description: 'Perfil',
      ),
    );
    await source.search(
      const MatchingSearchFilters(
        petId: 'mine',
        breedId: 7,
        minimumAgeMonths: 18,
        maximumAgeMonths: 72,
      ),
    );
    await source.getCandidate('mine', 'candidate');
    await source.sendRequest(
      petId: 'mine',
      candidatePetId: 'candidate',
      message: 'Hola',
    );
    await source.requestAction('request-1', 'accept', sharePhoneNumber: true);
    await source.requestAction('request-1', 'reject');
    await source.requestAction('request-1', 'cancel');
    await source.getMatches();
    await source.getMatch('match-1');
    await source.getBreedingIntent('match-1');
    await source.proposeBreedingIntent('match-1', notes: 'Futura camada');
    await source.breedingIntentAction('intent-1', 'accept');
    await source.breedingIntentAction('intent-1', 'cancel');

    expect(recorder.requests[0].path, '/api/v1/matching/profiles/mine');
    expect(recorder.requests[1].path, '/api/v1/matching/profiles');
    expect(recorder.requests[1].data, containsPair('preferredBreedIds', [7]));
    expect(recorder.requests[1].data, containsPair('lookingForSex', 'F'));
    expect(recorder.requests[2].path, '/api/v1/matching/search');
    expect(recorder.requests[2].queryParameters, containsPair('breedId', 7));
    expect(
      recorder.requests[2].queryParameters,
      containsPair('minAgeMonths', 18),
    );
    expect(recorder.requests[3].queryParameters, {'sourcePetId': 'mine'});
    expect(recorder.requests[4].data, {
      'petId': 'mine',
      'candidatePetId': 'candidate',
      'message': 'Hola',
      'sharePhoneNumber': false,
    });
    expect(recorder.requests[5].data, {'sharePhoneNumber': true});
    expect(recorder.requests[6].data, isNull);
    expect(recorder.requests[7].data, isNull);
    expect(recorder.requests[8].path, '/api/v1/matching/matches');
    expect(recorder.requests[9].path, '/api/v1/matching/matches/match-1');
    expect(
      recorder.requests[10].path,
      '/api/v1/matching/matches/match-1/breeding-intent',
    );
    expect(
      recorder.requests[11].path,
      '/api/v1/matching/matches/match-1/breeding-intents',
    );
    expect(
      recorder.requests[12].path,
      '/api/v1/matching/breeding-intents/intent-1/accept',
    );
    expect(
      recorder.requests[13].path,
      '/api/v1/matching/breeding-intents/intent-1/cancel',
    );
  });
}

class _RecordingDio {
  _RecordingDio() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(
            Response<dynamic>(
              requestOptions: request,
              statusCode: request.method == 'POST' ? 201 : 200,
              data: _response(request.path),
            ),
          );
        },
      ),
    );
  }
  final Dio dio = Dio();
  final requests = <RequestOptions>[];
}

Object _response(String path) {
  if (path.endsWith('/profiles/mine') || path.endsWith('/profiles')) {
    return _profile;
  }
  if (path.endsWith('/search')) {
    return {
      'items': [_candidate],
      'pageNumber': 1,
      'pageSize': 50,
      'totalItems': 1,
    };
  }
  if (path.contains('/pets/candidate')) return _candidate;
  if (path.endsWith('/matches')) return [_match];
  if (path.endsWith('/matches/match-1')) return _matchDetail;
  if (path.contains('breeding-intent')) return _intent;
  return _request;
}

final _profile = {
  'matchingProfileId': 'profile-1',
  'petId': 'mine',
  'isActive': true,
  'preferredBreedIds': [7],
  'minimumAgeMonths': 12,
  'maximumAgeMonths': 84,
  'requirePedigree': false,
  'requireGenealogyValidation': true,
  'maximumEstimatedInbreedingCoefficient': .125,
  'minimumCompatibilityScore': 60,
  'createdAt': '2026-08-25T00:00:00Z',
  'updatedAt': null,
  'lookingForSex': 'F',
  'allowMixedBreed': true,
  'description': 'Perfil',
  'availableFromUtc': null,
};
final _candidate = {
  'petId': 'candidate',
  'name': 'Luna',
  'breedId': 7,
  'breedName': 'Golden',
  'sex': 'F',
  'ageMonths': 36,
  'mainPhotoUrl': '/luna.jpg',
  'compatibilityScore': 90,
  'compatibilityBreakdown': {
    'breedScore': 20,
    'ageScore': 20,
    'pedigreeScore': 20,
    'genealogyScore': 20,
    'healthScore': 10,
  },
  'pedigreeCompletenessPercentage': 90.0,
  'relationshipType': 9,
  'estimatedOffspringInbreedingCoefficient': .1,
  'genealogyStatus': 0,
  'healthCompatibilityStatus': 1,
  'isFavorite': false,
  'warnings': ['Related'],
  'speciesName': 'Perro',
  'color': 'Dorado',
  'description': 'Cariñosa',
  'relationshipStatus': 'Related',
  'relationshipDescription': 'Primos',
  'photoUrls': ['/luna.jpg'],
  'disclaimer': 'Informativo',
};
final _pet = {
  'petId': 'mine',
  'name': 'Andrea',
  'speciesName': 'Gato',
  'breedName': 'Mestizo',
  'sex': 'M',
  'ageMonths': 24,
  'mainPhotoUrl': null,
  'color': null,
};
final _request = {
  'matchRequestId': 'request-1',
  'requesterPetId': 'mine',
  'candidatePetId': 'candidate',
  'status': 0,
  'message': 'Hola',
  'compatibilityScoreSnapshot': 90,
  'estimatedInbreedingCoefficientSnapshot': 0.0,
  'relationshipTypeSnapshot': 11,
  'createdAt': '2026-08-25T00:00:00Z',
  'updatedAt': null,
  'respondedAt': null,
  'cancelledAt': null,
  'expiresAt': null,
  'requesterPet': _pet,
  'targetPet': {..._pet, 'petId': 'candidate', 'name': 'Luna'},
};
final _match = {
  'matchId': 'match-1',
  'pet1': _pet,
  'pet2': {..._pet, 'petId': 'candidate', 'name': 'Luna'},
  'createdAtUtc': '2026-08-25T00:00:00Z',
};
final _matchDetail = {
  ..._match,
  'status': 'Accepted',
  'pet1Owner': {'displayName': 'Jorge', 'phoneNumber': '+51999'},
  'pet2Owner': {'displayName': 'Ana', 'phoneNumber': null},
  'breedingIntent': {
    'breedingIntentId': 'intent-1',
    'status': 'Proposed',
    'notes': 'Futura camada',
    'expectedDateUtc': null,
    'createdAtUtc': '2026-08-25T00:00:00Z',
    'proposedByCurrentUser': true,
  },
};
final _intent = {
  'breedingIntentId': 'intent-1',
  'matchId': 'match-1',
  'status': 'Proposed',
  'notes': 'Futura camada',
  'expectedDateUtc': null,
  'createdAtUtc': '2026-08-25T00:00:00Z',
  'acceptedAtUtc': null,
  'cancelledAtUtc': null,
  'proposedByCurrentUser': true,
};
