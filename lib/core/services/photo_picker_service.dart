import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

enum PhotoSource { gallery, camera }

class SelectedPhoto {
  const SelectedPhoto({
    required this.file,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
  });

  final XFile file;
  final String fileName;
  final String contentType;
  final int fileSize;
}

class PreparedPhotoUpload {
  const PreparedPhotoUpload({
    required this.fileName,
    required this.contentType,
    required this.imageBase64,
  });

  final String fileName;
  final String contentType;
  final String imageBase64;
}

class PhotoValidationException implements Exception {
  const PhotoValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

sealed class PhotoSelectionResult {
  const PhotoSelectionResult();
}

class PhotoSelected extends PhotoSelectionResult {
  const PhotoSelected(this.photo);
  final SelectedPhoto photo;
}

class PhotoSelectionCancelled extends PhotoSelectionResult {
  const PhotoSelectionCancelled();
}

class PhotoSelectionInvalid extends PhotoSelectionResult {
  const PhotoSelectionInvalid(this.message);
  final String message;
}

abstract class PhotoPickerService {
  Future<PhotoSelectionResult> pick(PhotoSource source);
}

class ImagePickerPhotoPickerService implements PhotoPickerService {
  ImagePickerPhotoPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const maxBytes = 10 * 1024 * 1024;
  static const maxDimension = 1600.0;
  static const jpegQuality = 82;
  final ImagePicker _picker;

  @override
  Future<PhotoSelectionResult> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: jpegQuality,
    );
    if (file == null) return const PhotoSelectionCancelled();

    final size = await file.length();
    final validation = validatePhoto(file.name, size);
    if (validation != null) return PhotoSelectionInvalid(validation);

    return PhotoSelected(
      SelectedPhoto(
        file: file,
        fileName: file.name,
        contentType: contentTypeFor(file.name),
        fileSize: size,
      ),
    );
  }

  static String? validatePhoto(String fileName, int fileSize) {
    final extension = fileName.split('.').last.toLowerCase();
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      return 'Selecciona una imagen JPG, PNG o WebP.';
    }
    if (fileSize > maxBytes) {
      return 'La imagen es demasiado grande. '
          'El tamaño máximo permitido es 10 MB.';
    }
    return null;
  }

  static String contentTypeFor(String fileName) {
    return switch (fileName.split('.').last.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}

Future<PreparedPhotoUpload> preparePhotoUpload(SelectedPhoto photo) async {
  if (photo.file.path.isNotEmpty && !await File(photo.file.path).exists()) {
    throw const PhotoValidationException(
      'No se encontró la imagen seleccionada. Inténtalo nuevamente.',
    );
  }

  final bytes = await photo.file.readAsBytes();
  final validation = ImagePickerPhotoPickerService.validatePhoto(
    photo.fileName,
    bytes.length,
  );
  if (validation != null) throw PhotoValidationException(validation);

  final contentType = ImagePickerPhotoPickerService.contentTypeFor(
    photo.fileName,
  );
  if (contentType == 'application/octet-stream') {
    throw const PhotoValidationException(
      'No se pudo identificar el formato de la imagen.',
    );
  }

  return PreparedPhotoUpload(
    fileName: photo.fileName,
    contentType: contentType,
    imageBase64: base64Encode(bytes),
  );
}
