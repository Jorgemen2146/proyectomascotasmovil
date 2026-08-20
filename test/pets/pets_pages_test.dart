import 'package:dogplatform/features/pets/application/providers.dart';
import 'package:dogplatform/features/pets/domain/entities/pet.dart';
import 'package:dogplatform/features/pets/presentation/pages/pet_form_page.dart';
import 'package:dogplatform/features/pets/presentation/pages/pet_photos_page.dart';
import 'package:dogplatform/features/pets/presentation/pages/pets_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_pets_repository.dart';

void main() {
  testWidgets('lista vacía muestra CTA para primera mascota', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [myPetsProvider.overrideWith((ref) async => const [])],
        child: const MaterialApp(home: PetsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes mascotas'), findsOneWidget);
    expect(find.text('Agrega tu primera mascota'), findsOneWidget);
  });

  testWidgets('lista cargada muestra mascota y filtros', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPetsProvider.overrideWith((ref) async => [samplePetSummary]),
        ],
        child: const MaterialApp(home: PetsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Golden Retriever'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Perros'), findsOneWidget);
    expect(find.text('Gatos'), findsOneWidget);
  });

  testWidgets('formulario evita guardar datos requeridos vacíos', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speciesProvider.overrideWith(
            (ref) async => const [Species(speciesId: 1, name: 'Perro')],
          ),
          breedsProvider.overrideWith(
            (ref, speciesId) async => const [
              Breed(breedId: 10, speciesId: 1, name: 'Golden Retriever'),
            ],
          ),
        ],
        child: const MaterialApp(home: PetFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final save = find.text('Guardar');
    await tester.scrollUntilVisible(
      save,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(save);
    await tester.pump();

    expect(find.text('Ingresa el nombre.'), findsOneWidget);
  });

  testWidgets('galería muestra fotos recibidas', (tester) async {
    final photo = PetPhoto(
      photoId: 'photo-1',
      petId: 'pet-1',
      url: '',
      isMain: true,
      createdAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petPhotosProvider.overrideWith((ref, petId) async => [photo]),
        ],
        child: const MaterialApp(home: PetPhotosPage(petId: 'pet-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Principal'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('galería permite seleccionar una foto no principal', (
    tester,
  ) async {
    final photo = PetPhoto(
      photoId: 'photo-2',
      petId: 'pet-1',
      url: '',
      isMain: false,
      createdAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petPhotosProvider.overrideWith((ref, petId) async => [photo]),
        ],
        child: const MaterialApp(home: PetPhotosPage(petId: 'pet-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_outline), findsOneWidget);
  });
}
