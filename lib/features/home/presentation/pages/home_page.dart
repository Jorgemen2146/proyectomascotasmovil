import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/application/auth_state_controller.dart';

/// First-iteration Home screen. Intentionally empty aside from a welcome
/// message and a logout action — Pets/Genealogy/Matching/Health dashboards
/// will be added as those features are implemented.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DogPlatform'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome${authState.user != null ? ', ${authState.user!.fullName}' : ''}!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
