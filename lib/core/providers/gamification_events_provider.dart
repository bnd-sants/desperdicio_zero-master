import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/gamification_event.dart';
import 'package:desperdicio_zero/services/gamification_event_service.dart';
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart';

class GamificationEventsNotifier
    extends AsyncNotifier<List<GamificationEvent>> {
  late final GamificationEventService _service;

  @override
  Future<List<GamificationEvent>> build() async {
    _service = GamificationEventService();
    final authState = ref.watch(authNotifierProvider);
    final user = authState.maybeWhen(
      authenticated: (profile) => profile,
      orElse: () => null,
    );

    if (user == null) {
      return const [];
    }

    return _service.fetchEvents(userId: user.id);
  }

  Future<void> refresh() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.maybeWhen(
      authenticated: (profile) => profile,
      orElse: () => null,
    );

    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.fetchEvents(userId: user.id),
    );
  }
}

final gamificationEventsProvider = AsyncNotifierProvider<
    GamificationEventsNotifier, List<GamificationEvent>>(
  GamificationEventsNotifier.new,
);
