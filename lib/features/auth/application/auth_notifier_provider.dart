import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/features/auth/domain/auth_state.dart';
import 'package:desperdicio_zero/services/auth_service_wrapper.dart';
import 'auth_notifier.dart';

final authNotifierProvider = StateNotifierProvider.autoDispose<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});
