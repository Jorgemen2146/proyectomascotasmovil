import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/application/auth_state_controller.dart';

/// Bridges Riverpod's [authStateControllerProvider] changes into a
/// [Listenable], as required by GoRouter's `refreshListenable` parameter,
/// so route redirects re-evaluate whenever auth status changes.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authStateControllerProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}

final goRouterRefreshNotifierProvider = Provider<GoRouterRefreshNotifier>((
  ref,
) {
  return GoRouterRefreshNotifier(ref);
});
