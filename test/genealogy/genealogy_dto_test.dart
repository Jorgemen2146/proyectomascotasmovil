import 'package:dogplatform/features/genealogy/data/dto/genealogy_dtos.dart';
import 'package:dogplatform/features/genealogy/domain/entities/genealogy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodifica árbol recursivo, metadatos e hijos', () {
    final tree = GenealogyTreeDto.fromJson({
      'pet': _pet('root', 'Andrea Kitty', 'F'),
      'parents': [
        {
          'relationshipId': 'rel-father',
          'role': 'Father',
          'pet': _pet('father', 'Tom', 'M'),
          'parents': [
            {
              'relationshipId': 'rel-grandfather',
              'role': 'Father',
              'pet': _pet('grandfather', 'Simba', 'M'),
              'parents': <dynamic>[],
            },
          ],
        },
      ],
      'children': [
        {'relationshipId': 'rel-child', 'pet': _pet('child', 'Nina', 'F')},
      ],
    }).toDomain();

    expect(tree.pet.name, 'Andrea Kitty');
    expect(tree.parentFor(GenealogyParentRole.father)?.pet.name, 'Tom');
    expect(tree.parents.single.parents.single.pet.name, 'Simba');
    expect(tree.children.single.pet.name, 'Nina');
    expect(tree.pet.birthDate, DateTime.utc(2020));
  });

  test('decodifica invitación creada, contexto y listado', () {
    final created = InvitationCreatedDto.fromJson({
      'invitationId': 'i1',
      'status': 'Pending',
      'expiresAtUtc': '2026-09-01T00:00:00Z',
      'invitationToken': 'secret-token',
    }).toDomain();
    final item = InvitationListItemDto.fromJson({
      'invitationId': 'i1',
      'childPetId': 'root',
      'childPetName': 'Andrea Kitty',
      'parentRole': 'Mother',
      'direction': 'incoming',
      'status': 'Pending',
      'expiresAtUtc': '2026-09-01T00:00:00Z',
      'createdAtUtc': '2026-08-25T00:00:00Z',
    }).toDomain();

    expect(created.invitationToken, 'secret-token');
    expect(item.direction, 'incoming');
    expect(item.isPending, isTrue);
  });
}

Map<String, dynamic> _pet(String id, String name, String sex) => {
  'petId': id,
  'name': name,
  'sex': sex,
  'speciesId': 1,
  'breedName': 'Bombay',
  'mainPhotoUrl': '/photos/$id.jpg',
  'birthDate': '2020-01-01T00:00:00Z',
};
