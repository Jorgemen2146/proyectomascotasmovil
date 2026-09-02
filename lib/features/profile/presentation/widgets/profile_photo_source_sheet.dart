import 'package:flutter/material.dart';

import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/theme/app_icons.dart';

Future<PhotoSource?> showProfilePhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<PhotoSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(AppIcons.camera),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, PhotoSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de galería'),
            onTap: () => Navigator.pop(context, PhotoSource.gallery),
          ),
        ],
      ),
    ),
  );
}
