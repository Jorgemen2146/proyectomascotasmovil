import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../application/providers.dart';

class MessageButton extends ConsumerWidget {
  const MessageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      socialControllerProvider.select((state) => state.unreadMessages),
    );
    return IconButton(
      key: const Key('messageButton'),
      tooltip: 'Mensajes',
      onPressed: () => context.push(AppRoutes.messages),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(AppIcons.messages, color: AppColors.textPrimary, size: 26),
          if (count > 0)
            Positioned(
              top: -7,
              right: -10,
              child: Container(
                key: const Key('messageBadge'),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
