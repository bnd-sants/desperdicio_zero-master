import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger_util.dart';

class TelemetryService {
  TelemetryService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> logEvent({
    required String category,
    required String message,
    String severity = 'info',
    Map<String, dynamic>? data,
    String source = 'app',
  }) async {
    try {
      final type = category == 'security' ? 'security' : 'performance';
      await _client.from('advisors_reports').insert({
        'type': type,
        'details': {
          'category': category,
          'severity': severity,
          'message': message,
          'data': data,
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    } catch (e, stackTrace) {
      logWarning('Falha ao enviar telemetria: $e', e, stackTrace);
    }
  }
}
