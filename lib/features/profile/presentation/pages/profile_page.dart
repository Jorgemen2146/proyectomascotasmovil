import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/main_bottom_navigation.dart';
import '../../../authentication/application/auth_state_controller.dart';
import '../../application/profile_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: profile.when(
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
        data: (user) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(Icons.person, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              user.fullName,
              style: AppTypography.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              user.email,
              style: AppTypography.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Center(
              child: AppBadge(
                label: 'Correo verificado',
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ProfileOption(
                    icon: Icons.person_outline,
                    label: 'Editar perfil',
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  _ProfileOption(
                    icon: Icons.pets_outlined,
                    label: 'Mis mascotas',
                    onTap: () => context.go(AppRoutes.pets),
                  ),
                  _ProfileOption(
                    icon: Icons.settings_outlined,
                    label: 'Configuración',
                    onTap: () => _pending(context),
                  ),
                  _ProfileOption(
                    icon: Icons.shield_outlined,
                    label: 'Privacidad',
                    onTap: () => _pending(context),
                  ),
                  _ProfileOption(
                    icon: Icons.description_outlined,
                    label: 'Términos y condiciones',
                    onTap: () => _pending(context),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: _ProfileOption(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                color: AppColors.error,
                isLast: true,
                onTap: () => _logout(context, ref),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 3),
    );
  }

  void _pending(BuildContext context) {
    AppSnackBar.showInfo(
      context,
      'Esta sección estará disponible próximamente.',
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Cerrar sesión',
      message: '¿Deseas cerrar tu sesión?',
      confirmLabel: 'Cerrar sesión',
      cancelLabel: 'Cancelar',
      isDestructive: true,
    );
    if (!confirmed) return;
    await ref.read(authStateControllerProvider.notifier).logout();
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: color ?? AppColors.textSecondary),
          title: Text(label, style: TextStyle(color: color)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }
}
