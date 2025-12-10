import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider para o Supabase client
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
