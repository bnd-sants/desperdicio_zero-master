import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart';
import 'package:desperdicio_zero/services/metrics_service.dart';

class MetricsNotifier extends AsyncNotifier<MetricsSnapshot?> {
  late final MetricsService _service;

  @override
  Future<MetricsSnapshot?> build() async {
    _service = MetricsService();
    final authState = ref.watch(authNotifierProvider);
    final user = authState.when(
      authenticated: (profile) => profile,
      unauthenticated: () => null,
      loading: () => null,
      error: (_) => null,
      initial: () => null,
    );

    if (user == null) {
      return null;
    }

    return _service.fetchSnapshot(user.id);
  }

  Future<void> refresh() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.when(
      authenticated: (profile) => profile,
      unauthenticated: () => null,
      loading: () => null,
      error: (_) => null,
      initial: () => null,
    );

    if (user == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.fetchSnapshot(user.id),
    );
  }
}

final metricsProvider = AsyncNotifierProvider<MetricsNotifier, MetricsSnapshot?>(
  MetricsNotifier.new,
);
