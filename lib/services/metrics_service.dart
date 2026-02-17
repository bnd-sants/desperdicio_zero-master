import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/models/metrics_timeseries.dart';

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
    double numToDouble(dynamic value) {
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
      totalQuantity: numToDouble(data['total_quantity']),
      activeQuantity: numToDouble(data['active_quantity']),
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
    DateTime? parseDate(dynamic value) {
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
      lastReset: parseDate(data['last_reset']),
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

  Future<List<MonthlyWastePoint>> fetchMonthlyWasteSeries(
    String userId, {
    int months = 12,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (months - 1), 1);

    final response = await _supabase
        .from('products')
        .select('is_consumed, expiration_date, created_at')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String())
        .order('created_at', ascending: true);

    final monthly = <String, Map<String, int>>{};
    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthly[key] = {'consumed': 0, 'wasted': 0};
    }

    for (final item in (response as List)) {
      final consumed = item['is_consumed'] as bool? ?? false;
      final expirationRaw = item['expiration_date']?.toString();
      final createdRaw = item['created_at']?.toString();
      final createdAt = createdRaw != null ? DateTime.tryParse(createdRaw) : null;
      final expirationDate = expirationRaw != null ? DateTime.tryParse(expirationRaw) : null;
      final monthRef = createdAt ?? expirationDate;
      if (monthRef == null) continue;

      final key =
          '${monthRef.year}-${monthRef.month.toString().padLeft(2, '0')}';
      if (!monthly.containsKey(key)) continue;

      if (consumed) {
        monthly[key]!['consumed'] = (monthly[key]!['consumed'] ?? 0) + 1;
      } else if (expirationDate != null && expirationDate.isBefore(DateTime.now())) {
        monthly[key]!['wasted'] = (monthly[key]!['wasted'] ?? 0) + 1;
      }
    }

    final points = monthly.entries.map((entry) {
      final parts = entry.key.split('-');
      return MonthlyWastePoint(
        month: DateTime(int.parse(parts[0]), int.parse(parts[1]), 1),
        consumed: entry.value['consumed'] ?? 0,
        wasted: entry.value['wasted'] ?? 0,
      );
    }).toList();

    points.sort((a, b) => a.month.compareTo(b.month));
    return points;
  }

  Future<List<ForecastPoint>> forecastWaste30Days(String userId) async {
    final series = await fetchMonthlyWasteSeries(userId, months: 6);
    if (series.isEmpty) return [];

    final averageMonthlyWaste =
        series.map((p) => p.wasted).fold<int>(0, (sum, e) => sum + e) /
            series.length;
    final averageDailyWaste = averageMonthlyWaste / 30.0;
    final now = DateTime.now();

    return List.generate(30, (index) {
      return ForecastPoint(
        date: now.add(Duration(days: index + 1)),
        predictedWaste: averageDailyWaste,
      );
    });
  }
}
