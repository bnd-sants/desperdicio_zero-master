import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/gamification_event.dart';
import 'package:desperdicio_zero/services/gamification_event_service.dart';
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart';

class GamificationEventsNotifier
    extends AutoDisposeAsyncNotifier<List<GamificationEvent>> {
  GamificationEventsNotifier() : _service = GamificationEventService();

  final GamificationEventService _service;

  @override
  Future<List<GamificationEvent>> build() async {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! Authenticated) {
      return const [];
    }

    return _service.fetchEvents(userId: authState.user.id);
  }

  Future<void> refresh() async {
    final authState = ref.read(authNotifierProvider);
    if (authState is! Authenticated) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.fetchEvents(userId: authState.user.id),
    );
  }
}

final gamificationEventsProvider = AutoDisposeAsyncNotifierProvider<
    GamificationEventsNotifier, List<GamificationEvent>>(
  GamificationEventsNotifier.new,
);
