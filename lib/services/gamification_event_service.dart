import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/models/gamification_event.dart';

class GamificationEventService {
  GamificationEventService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<GamificationEvent>> fetchEvents({required String userId, int limit = 20}) async {
    final response = await _client
        .from('gamification_events')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((row) => GamificationEvent.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> logEvent({
    required String userId,
    required String eventType,
    required String title,
    String? description,
    int xpChange = 0,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('gamification_events').insert({
      'user_id': userId,
      'event_type': eventType,
      'title': title,
      'description': description,
      'xp_change': xpChange,
      'metadata': metadata ?? const <String, dynamic>{},
    });
  }
}
