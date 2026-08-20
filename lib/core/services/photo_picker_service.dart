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

  static const maxBytes = 5 * 1024 * 1024;
  final ImagePicker _picker;

  @override
  Future<PhotoSelectionResult> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 90,
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
      return 'La imagen no puede superar los 5 MB.';
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
