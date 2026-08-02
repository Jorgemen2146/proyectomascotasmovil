import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_state_controller.dart';

/// Shown while [AuthStateController] determines whether a valid session
/// exists. Navigation to Login/Home is handled entirely by the router's
/// redirect logic once the status resolves.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching keeps the controller alive and triggers session restoration.
    ref.watch(authStateControllerProvider);

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 64),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
