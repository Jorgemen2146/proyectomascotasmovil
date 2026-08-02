import 'package:flutter/foundation.dart';

/// Minimal, framework-agnostic event bus used by [core] to signal that the
/// current session has expired (refresh token failed) without core having
/// to depend on any feature module.
///
/// The authentication feature listens to [sessionExpiredTick] and reacts by
/// transitioning its auth state to unauthenticated, which in turn drives
/// the GoRouter redirect back to the login screen.
class SessionEvents {
  SessionEvents._();

  static final ValueNotifier<int> sessionExpiredTick = ValueNotifier<int>(0);

  static void notifySessionExpired() {
    sessionExpiredTick.value++;
  }
}
