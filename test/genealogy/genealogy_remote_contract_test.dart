import 'package:dio/dio.dart';
import 'package:dogplatform/features/genealogy/data/datasources/genealogy_remote_data_source.dart';
import 'package:dogplatform/features/genealogy/domain/entities/genealogy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa rutas, verbos, query y bodies exactos del contrato', () async {
    final recorder = _RecordingDio();
    final source = GenealogyRemoteDataSource(dio: recorder.dio);

    await source.getTree('child', 3);
    await source.addOwnParent('child', 'father', GenealogyParentRole.father);
    await source.deleteRelationship('relationship');
    await source.createInvitation(
      'child',
      GenealogyParentRole.mother,
      'owner@example.com',
    );
    await source.getInvitation('token');
    await source.getInvitations('incoming', 'Pending');
    await source.acceptInvitation('token', 'parent');
    await source.rejectInvitation('token');
    await source.cancelInvitation('invitation');

    expect(recorder.requests[0].path, '/api/v1/genealogy/pets/child/tree');
    expect(recorder.requests[0].queryParameters, {'generations': 3});
    expect(recorder.requests[1].path, '/api/v1/genealogy/pets/child/parents');
    expect(recorder.requests[1].data, {
      'parentPetId': 'father',
      'parentRole': 'Father',
    });
    expect(recorder.requests[2].method, 'DELETE');
    expect(
      recorder.requests[2].path,
      '/api/v1/genealogy/relationships/relationship',
    );
    expect(recorder.requests[3].data, {
      'childPetId': 'child',
      'parentRole': 'Mother',
      'ownerEmail': 'owner@example.com',
    });
    expect(recorder.requests[4].path, '/api/v1/genealogy/invitations/token');
    expect(recorder.requests[5].queryParameters, {
      'direction': 'incoming',
      'status': 'Pending',
    });
    expect(recorder.requests[6].data, {'petId': 'parent'});
    expect(
      recorder.requests[7].path,
      '/api/v1/genealogy/invitations/token/reject',
    );
    expect(
      recorder.requests[8].path,
      '/api/v1/genealogy/invitations/invitation/cancel',
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
              statusCode: request.method == 'DELETE' ? 204 : 200,
              data: _responseFor(request),
            ),
          );
        },
      ),
    );
  }

  final Dio dio = Dio();
  final List<RequestOptions> requests = [];

  dynamic _responseFor(RequestOptions request) {
    if (request.method == 'DELETE' ||
        request.path.endsWith('/reject') ||
        request.path.endsWith('/cancel')) {
      return null;
    }
    if (request.path.endsWith('/tree')) {
      return {
        'pet': _pet('child'),
        'parents': <dynamic>[],
        'children': <dynamic>[],
      };
    }
    if (request.path.endsWith('/mine')) return <dynamic>[];
    if (request.path.endsWith('/parents') || request.path.endsWith('/accept')) {
      return {'relationshipId': 'relationship', 'status': 'Active'};
    }
    if (request.path == '/api/v1/genealogy/invitations') {
      return {
        'invitationId': 'invitation',
        'status': 'Pending',
        'expiresAtUtc': '2026-09-01T00:00:00Z',
        'invitationToken': 'token',
      };
    }
    return {
      'invitationId': 'invitation',
      'requesterDisplayName': 'Jorge',
      'childPetId': 'child',
      'childPetName': 'Andrea Kitty',
      'childMainPhotoUrl': null,
      'parentRole': 'Father',
      'expiresAtUtc': '2026-09-01T00:00:00Z',
      'status': 'Pending',
    };
  }
}

Map<String, dynamic> _pet(String id) => {
  'petId': id,
  'name': 'Pet',
  'sex': 'F',
  'speciesId': 1,
  'breedName': null,
  'mainPhotoUrl': null,
  'birthDate': null,
};
