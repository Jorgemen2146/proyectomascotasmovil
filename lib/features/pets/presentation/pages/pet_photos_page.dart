import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../application/providers.dart';
import '../../domain/entities/pet.dart';

class PetPhotosPage extends ConsumerWidget {
  const PetPhotosPage({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(petPhotosProvider(petId));
    final isUploading = ref.watch(petPhotoControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Fotos de la mascota')),
      body: photos.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(petPhotosProvider(petId)),
        ),
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.photo_library_outlined,
                title: 'Aún no hay fotos',
                message: 'Agrega la primera foto de tu mascota.',
                actionLabel: 'Agregar foto',
                onAction: isUploading
                    ? null
                    : () => _pickAndUpload(context, ref),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.9,
                ),
                itemCount: items.length,
                itemBuilder: (_, index) => _PhotoTile(
                  photo: items[index],
                  onDelete: () => _delete(context, ref, items[index]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isUploading ? null : () => _pickAndUpload(context, ref),
        icon: isUploading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_a_photo_outlined),
        label: Text(isUploading ? 'Subiendo' : 'Agregar foto'),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, PhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, PhotoSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final selection = await ref.read(photoPickerServiceProvider).pick(source);
    if (!context.mounted) return;
    if (selection is PhotoSelectionInvalid) {
      AppSnackBar.showError(context, selection.message);
      return;
    }
    if (selection is! PhotoSelected) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vista previa'),
        content: ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: Image.file(
            File(selection.photo.file.path),
            height: 240,
            fit: BoxFit.cover,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Subir foto'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(petPhotoControllerProvider.notifier)
        .upload(petId, selection.photo);
    if (!context.mounted) return;
    if (result.isFailure) {
      AppSnackBar.showError(context, result.failureOrNull!.message);
    } else {
      AppSnackBar.showSuccess(context, 'Foto agregada correctamente.');
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PetPhoto photo,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Eliminar foto',
      message: '¿Deseas eliminar esta foto?',
      confirmLabel: 'Eliminar',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(petPhotoControllerProvider.notifier)
        .delete(petId, photo.photoId);
    if (!context.mounted) return;
    if (result.isFailure) {
      AppSnackBar.showError(context, result.failureOrNull!.message);
    }
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onDelete});
  final PetPhoto photo;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AppNetworkImage(
          url: photo.url,
          borderRadius: AppRadius.mdAll,
          fit: BoxFit.cover,
        ),
        if (photo.isMain)
          const Positioned(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Chip(label: Text('Principal')),
          ),
        Positioned(
          right: AppSpacing.xs,
          top: AppSpacing.xs,
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
