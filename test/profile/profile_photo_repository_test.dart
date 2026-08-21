import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dogplatform/core/services/photo_picker_service.dart';
import 'package:dogplatform/core/storage/secure_token_storage.dart';
import 'package:dogplatform/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:dogplatform/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('repositorio genera Base64 puro para la foto de perfil', () async {
    final remote = _RecordingPhotoRemoteDataSource();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: _NoopTokenStorage(),
    );
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final result = await repository.uploadProfilePhoto(
      SelectedPhoto(
        file: XFile.fromData(bytes, name: 'jorge.jpg'),
        fileName: 'jorge.jpg',
        contentType: 'image/jpeg',
        fileSize: bytes.length,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(remote.fileName, 'jorge.jpg');
    expect(remote.contentType, 'image/jpeg');
    expect(remote.imageBase64, 'AQIDBA==');
    expect(remote.imageBase64, isNot(startsWith('data:')));
  });

  test('foto mayor a 10 MB se rechaza antes del POST', () async {
    final remote = _RecordingPhotoRemoteDataSource();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      tokenStorage: _NoopTokenStorage(),
    );
    final bytes = Uint8List(ImagePickerPhotoPickerService.maxBytes + 1);

    final result = await repository.uploadProfilePhoto(
      SelectedPhoto(
        file: XFile.fromData(bytes, name: 'grande.jpg'),
        fileName: 'grande.jpg',
        contentType: 'image/jpeg',
        fileSize: bytes.length,
      ),
    );

    expect(result.failureOrNull?.message, contains('10 MB'));
    expect(remote.calls, 0);
  });
}

class _RecordingPhotoRemoteDataSource extends AuthRemoteDataSource {
  _RecordingPhotoRemoteDataSource()
    : super(authenticatedDio: Dio(), rawDio: Dio());

  int calls = 0;
  String? fileName;
  String? contentType;
  String? imageBase64;

  @override
  Future<void> uploadProfilePhoto({
    required String fileName,
    required String contentType,
    required String imageBase64,
  }) async {
    calls++;
    this.fileName = fileName;
    this.contentType = contentType;
    this.imageBase64 = imageBase64;
  }
}

class _NoopTokenStorage extends SecureTokenStorage {}
