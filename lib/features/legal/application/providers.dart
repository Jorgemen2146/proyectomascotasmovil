import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/application/auth_state.dart';
import '../../authentication/application/auth_state_controller.dart';
import '../domain/entities/legal.dart';
import 'legal_data_providers.dart';

export 'legal_data_providers.dart';

final legalGateProvider = FutureProvider.autoDispose<LegalStatus?>((ref) async {
  final auth = ref.watch(authStateControllerProvider);
  if (auth.status != AuthStatus.authenticated) return null;
  return ref.watch(legalStatusProvider.future);
});
