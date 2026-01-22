import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_notifier_provider.dart'
    as feature_auth_provider;
import '../../../models/user_profile.dart';

export '../../../features/auth/domain/auth_state.dart';

/// Reexporta o provider oficial da feature para compatibilidade com imports antigos.
final authNotifierProvider = feature_auth_provider.authNotifierProvider;

final currentUserProvider = Provider<UserProfile?>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state.maybeWhen(
    authenticated: (profile) => profile,
    orElse: () => null,
  );
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(authNotifierProvider);
  return state.maybeWhen(
    authenticated: (_) => true,
    orElse: () => false,
  );
});
