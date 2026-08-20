import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../theme/app_icons.dart';
import 'app_bottom_nav_bar.dart';

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = [
    AppBottomNavItem(
      icon: AppIcons.homeOutlined,
      selectedIcon: AppIcons.home,
      label: 'Inicio',
    ),
    AppBottomNavItem(
      icon: AppIcons.petsOutlined,
      selectedIcon: AppIcons.pets,
      label: 'Mascotas',
    ),
    AppBottomNavItem(
      icon: AppIcons.healthOutlined,
      selectedIcon: AppIcons.health,
      label: 'Salud',
    ),
    AppBottomNavItem(
      icon: AppIcons.profileOutlined,
      selectedIcon: AppIcons.profile,
      label: 'Perfil',
    ),
  ];

  static const _routes = [
    AppRoutes.home,
    AppRoutes.pets,
    AppRoutes.health,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return AppBottomNavBar(
      items: _items,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) context.go(_routes[index]);
      },
    );
  }
}
