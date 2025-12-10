import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart';
import 'package:desperdicio_zero/services/metrics_service.dart';

class MetricsNotifier extends AutoDisposeAsyncNotifier<MetricsSnapshot?> {
  MetricsNotifier() : _service = MetricsService();

  final MetricsService _service;

  @override
  Future<MetricsSnapshot?> build() async {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! Authenticated) {
      return null;
    }

    return _service.fetchSnapshot(authState.user.id);
  }

  Future<void> refresh() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! Authenticated) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.fetchSnapshot(authState.user.id),
    );
  }
}

final metricsProvider = AutoDisposeAsyncNotifierProvider<MetricsNotifier, MetricsSnapshot?>(
  MetricsNotifier.new,
);
