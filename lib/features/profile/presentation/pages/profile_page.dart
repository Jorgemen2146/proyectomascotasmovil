import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/photo_picker_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/main_bottom_navigation.dart';
import '../../../authentication/application/auth_state_controller.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../application/profile_controller.dart';
import '../widgets/profile_photo_source_sheet.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profile.when(
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(profileControllerProvider),
          ),
          data: (user) => _ProfileContent(user: user),
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 4),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          key: const Key('profileScrollView'),
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            _ProfileIdentity(
              user: user,
              onPhotoTap: () => _changeProfilePhoto(context, ref),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.section,
              ),
              child: Column(
                children: [
                  _ProfileSectionCard(
                    title: 'CUENTA',
                    options: [
                      _ProfileOptionData(
                        icon: AppIcons.person,
                        label: 'Editar perfil',
                        onTap: () => context.push(AppRoutes.editProfile),
                      ),
                      _ProfileOptionData(
                        icon: AppIcons.petsOutlined,
                        label: 'Mis mascotas',
                        onTap: () => context.go(AppRoutes.pets),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  _ProfileSectionCard(
                    title: 'PREFERENCIAS',
                    options: [
                      _ProfileOptionData(
                        icon: AppIcons.settings,
                        label: 'Configuración',
                        onTap: () => AppSnackBar.showInfo(
                          context,
                          'Esta sección estará disponible próximamente.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  _ProfileSectionCard(
                    title: 'LEGAL',
                    options: [
                      _ProfileOptionData(
                        icon: AppIcons.legal,
                        label: 'Términos y condiciones',
                        onTap: () => context.push(AppRoutes.legalTerms),
                      ),
                      _ProfileOptionData(
                        icon: AppIcons.privacy,
                        label: 'Privacidad',
                        onTap: () => context.push(AppRoutes.legalPrivacy),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.compact),
                  _LogoutCard(onTap: () => _showLogoutSheet(context, ref)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.user, required this.onPhotoTap});

  final User user;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 382,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ClipPath(
            clipper: _ProfileHeaderClipper(),
            child: Container(
              height: 225,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.profileHeaderStart,
                    AppColors.profileHeaderEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 34,
                    top: 76,
                    child: Icon(
                      AppIcons.pets,
                      size: 52,
                      color: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                  Positioned(
                    right: 28,
                    top: 112,
                    child: Icon(
                      AppIcons.pets,
                      size: 66,
                      color: Colors.white.withValues(alpha: .28),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.section,
            child: Text('Mi Perfil', style: AppTypography.screenTitle),
          ),
          Positioned(
            top: 125,
            child: _ProfileAvatar(
              photoUrl: user.profilePhotoUrl,
              onTap: onPhotoTap,
            ),
          ),
          Positioned(
            top: 278,
            left: AppSpacing.section,
            right: AppSpacing.section,
            child: Column(
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.h1,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.onTap});

  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 128,
          height: 128,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
          ),
          child: ClipOval(
            child: AppNetworkImage(url: photoUrl, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: -4,
          bottom: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: AppShadows.floatingBlue,
            ),
            child: IconButton(
              key: const Key('profileCameraButton'),
              tooltip: 'Cambiar foto',
              onPressed: onTap,
              color: Colors.white,
              iconSize: 20,
              icon: const Icon(AppIcons.camera),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.title, required this.options});

  final String title;
  final List<_ProfileOptionData> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.section,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: AppColors.border.withValues(alpha: .75)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.sm),
          for (final option in options) _ProfileOption(data: option),
        ],
      ),
    );
  }
}

class _ProfileOptionData {
  const _ProfileOptionData({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({required this.data});

  final _ProfileOptionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        minLeadingWidth: 26,
        contentPadding: EdgeInsets.zero,
        leading: Icon(data.icon, color: AppColors.navigationInactive, size: 24),
        title: Text(
          data.label,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          AppIcons.chevronRight,
          size: 22,
          color: AppColors.textPrimary,
        ),
        onTap: data.onTap,
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.logoutSoft,
      borderRadius: AppRadius.cardAll,
      child: InkWell(
        key: const Key('profileLogoutButton'),
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.section,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              const Icon(AppIcons.logout, color: AppColors.error),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Cerrar sesión',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showLogoutSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (sheetContext) => _LogoutBottomSheet(
      onConfirm: () async {
        Navigator.of(sheetContext).pop();
        await ref.read(authStateControllerProvider.notifier).logout();
      },
    ),
  );
}

Future<void> _changeProfilePhoto(BuildContext context, WidgetRef ref) async {
  final source = await showProfilePhotoSourceSheet(context);
  if (source == null || !context.mounted) return;
  final selection = await ref.read(profilePhotoPickerProvider).pick(source);
  if (!context.mounted) return;
  switch (selection) {
    case PhotoSelected(:final photo):
      final outcome = await ref
          .read(profileControllerProvider.notifier)
          .updatePhoto(photo);
      if (!context.mounted) return;
      if (outcome == null ||
          outcome.photoFailure != null ||
          outcome.refreshFailure != null) {
        AppSnackBar.showError(context, 'No se pudo actualizar la foto.');
      } else {
        AppSnackBar.showSuccess(context, 'Foto actualizada correctamente.');
      }
    case PhotoSelectionInvalid(:final message):
      AppSnackBar.showError(context, message);
    case PhotoSelectionCancelled():
      break;
  }
}

class _LogoutBottomSheet extends StatelessWidget {
  const _LogoutBottomSheet({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Container(
      height: height * (height < 700 ? .68 : .52),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.compact,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  color: AppColors.logoutSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.logout,
                  color: AppColors.error,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('¿Cerrar sesión?', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '¿Seguro que quieres salir de tu cuenta de PetLife? '
                'Puedes iniciar sesión nuevamente cuando lo desees.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(height: 1.55),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  key: const Key('confirmLogoutButton'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                  ),
                  onPressed: onConfirm,
                  child: const Text('Cerrar sesión'),
                ),
              ),
              const SizedBox(height: AppSpacing.compact),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  key: const Key('cancelLogoutButton'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.primaryFaint,
                    side: const BorderSide(color: AppColors.primarySoft),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 30)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + 18,
        size.width,
        size.height - 30,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
