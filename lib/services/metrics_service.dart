import 'package:supabase_flutter/supabase_flutter.dart';

class ProductMetrics {
  final int totalItems;
  final int consumedItems;
  final int expiredItems;
  final int expiringSoonItems;
  final int activeItems;
  final double totalQuantity;
  final double activeQuantity;

  const ProductMetrics({
    required this.totalItems,
    required this.consumedItems,
    required this.expiredItems,
    required this.expiringSoonItems,
    required this.activeItems,
    required this.totalQuantity,
    required this.activeQuantity,
  });

  factory ProductMetrics.fromMap(Map<String, dynamic> data) {
    double _numToDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return ProductMetrics(
      totalItems: (data['total_items'] as num?)?.toInt() ?? 0,
      consumedItems: (data['consumed_items'] as num?)?.toInt() ?? 0,
      expiredItems: (data['expired_items'] as num?)?.toInt() ?? 0,
      expiringSoonItems: (data['expiring_soon_items'] as num?)?.toInt() ?? 0,
      activeItems: (data['active_items'] as num?)?.toInt() ?? 0,
      totalQuantity: _numToDouble(data['total_quantity']),
      activeQuantity: _numToDouble(data['active_quantity']),
    );
  }
}

class GamificationSummary {
  final int xpTotal;
  final int currentLevel;
  final int xpNextLevel;
  final DateTime? lastReset;
  final int completedMissions;
  final int activeMissions;
  final int unlockedBadges;

  const GamificationSummary({
    required this.xpTotal,
    required this.currentLevel,
    required this.xpNextLevel,
    required this.lastReset,
    required this.completedMissions,
    required this.activeMissions,
    required this.unlockedBadges,
  });

  factory GamificationSummary.fromMap(Map<String, dynamic> data) {
    DateTime? _parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return GamificationSummary(
      xpTotal: (data['xp_total'] as num?)?.toInt() ?? 0,
      currentLevel: (data['current_level'] as num?)?.toInt() ?? 1,
      xpNextLevel: (data['xp_next_level'] as num?)?.toInt() ?? 200,
      lastReset: _parseDate(data['last_reset']),
      completedMissions: (data['completed_missions'] as num?)?.toInt() ?? 0,
      activeMissions: (data['active_missions'] as num?)?.toInt() ?? 0,
      unlockedBadges: (data['unlocked_badges'] as num?)?.toInt() ?? 0,
    );
  }
}

class MetricsSnapshot {
  final ProductMetrics? productMetrics;
  final GamificationSummary? gamificationSummary;

  const MetricsSnapshot({
    required this.productMetrics,
    required this.gamificationSummary,
  });
}

class MetricsService {
  MetricsService() : _supabase = Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<ProductMetrics?> fetchProductMetrics(String userId) async {
    final response = await _supabase
        .from('v_product_metrics')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return ProductMetrics.fromMap(response);
  }

  Future<GamificationSummary?> fetchGamificationSummary(String userId) async {
    final response = await _supabase
        .from('v_gamification_progress')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return GamificationSummary.fromMap(response);
  }

  Future<MetricsSnapshot> fetchSnapshot(String userId) async {
    final results = await Future.wait([
      fetchProductMetrics(userId),
      fetchGamificationSummary(userId),
    ]);

    return MetricsSnapshot(
      productMetrics: results[0] as ProductMetrics?,
      gamificationSummary: results[1] as GamificationSummary?,
    );
  }
}
