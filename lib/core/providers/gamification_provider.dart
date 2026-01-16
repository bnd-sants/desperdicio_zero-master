import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/gamification_models.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/services/gamification_event_service.dart';

class GamificationState {
  final List<GamificationMission> missions;
  final List<GamificationBadge> badges;
  final int xpTotal;
  final int currentLevel;
  final int xpNextLevel;
  final List<String> recentlyCompletedMissions;
  final int lastXpGained;
  final DateTime lastReset;

  GamificationState({
    required this.missions,
    required this.badges,
    required this.xpTotal,
    required this.currentLevel,
    required this.xpNextLevel,
    this.recentlyCompletedMissions = const [],
    this.lastXpGained = 0,
    DateTime? lastReset,
  }) : lastReset = lastReset ?? DateTime.now();

  GamificationState copyWith({
    List<GamificationMission>? missions,
    List<GamificationBadge>? badges,
    int? xpTotal,
    int? currentLevel,
    int? xpNextLevel,
    List<String>? recentlyCompletedMissions,
    int? lastXpGained,
    DateTime? lastReset,
  }) => GamificationState(
        missions: missions ?? this.missions,
        badges: badges ?? this.badges,
        xpTotal: xpTotal ?? this.xpTotal,
        currentLevel: currentLevel ?? this.currentLevel,
        xpNextLevel: xpNextLevel ?? this.xpNextLevel,
        recentlyCompletedMissions:
            recentlyCompletedMissions ?? this.recentlyCompletedMissions,
        lastXpGained: lastXpGained ?? this.lastXpGained,
        lastReset: lastReset ?? this.lastReset,
      );
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier()
      : _supabase = Supabase.instance.client,
        _eventService = GamificationEventService(),
        super(GamificationState(
          missions: [],
          badges: [],
          xpTotal: 0,
          currentLevel: 1,
          xpNextLevel: 200,
          recentlyCompletedMissions: const [],
          lastXpGained: 0,
          lastReset: DateTime.now(),
        )) {
    _populateInitialMissionsAndBadges();
    Future.microtask(_loadFromBackend);
  }

  final SupabaseClient _supabase;
  final GamificationEventService _eventService;

  List<GamificationMission> _defaultMissions() => [
        const GamificationMission(
          id: 'add_products',
          title: 'Adicione Produtos',
          description: 'Adicione 3 produtos à sua despensa',
          progress: 0,
          goal: 3,
          xpReward: 50,
          icon: Icons.add_shopping_cart,
        ),
        const GamificationMission(
          id: 'stock_manager',
          title: 'Gestor de Despensa',
          description: 'Mantenha a despensa cheia adicionando 10 produtos',
          progress: 0,
          goal: 10,
          xpReward: 120,
          icon: Icons.inventory_rounded,
        ),
        const GamificationMission(
          id: 'sustainable_eater',
          title: 'Consumo Consciente',
          description: 'Consuma 5 itens antes que estraguem',
          progress: 0,
          goal: 5,
          xpReward: 90,
          icon: Icons.local_florist,
        ),
        const GamificationMission(
          id: 'consume_critical',
          title: 'Salvar Críticos',
          description: 'Consuma 3 produtos críticos nesta semana',
          progress: 0,
          goal: 3,
          xpReward: 120,
          icon: Icons.warning_amber_rounded,
        ),
        const GamificationMission(
          id: 'critical_rescuer',
          title: 'Herói da Geladeira',
          description: 'Resgate 5 produtos críticos a tempo',
          progress: 0,
          goal: 5,
          xpReward: 180,
          icon: Icons.volunteer_activism,
        ),
        const GamificationMission(
          id: 'complete_recipe',
          title: 'Mão na Massa',
          description: 'Finalize 1 receita usando itens do app',
          progress: 0,
          goal: 1,
          xpReward: 80,
          icon: Icons.restaurant_menu_outlined,
        ),
        const GamificationMission(
          id: 'recipe_master',
          title: 'Chef da Semana',
          description: 'Prepare 3 receitas com ingredientes salvos',
          progress: 0,
          goal: 3,
          xpReward: 150,
          icon: Icons.local_dining,
        ),
        const GamificationMission(
          id: 'zero_waste',
          title: 'Descarte Consciente',
          description: 'Registre 1 descarte com consciência na semana',
          progress: 0,
          goal: 1,
          xpReward: 60,
          icon: Icons.eco_outlined,
        ),
        const GamificationMission(
          id: 'waste_tracker',
          title: 'Analista de Desperdício',
          description: 'Informe 3 descartes para aprender com eles',
          progress: 0,
          goal: 3,
          xpReward: 110,
          icon: Icons.analytics_outlined,
        ),
      ];

  void _populateInitialMissionsAndBadges() {
    final initialMissions = _defaultMissions();
    final initialBadges = [
      GamificationBadge(
        id: 'first_mission',
        title: 'Primeira Missão',
        description: 'Complete qualquer missão',
        icon: Icons.emoji_events,
        color: const Color(0xFFFFD600),
        unlocked: false,
      ),
      GamificationBadge(
        id: 'no_waste_week',
        title: 'Semana Sustentável',
        description: 'Não desperdice nenhum item por 7 dias',
        icon: Icons.verified_outlined,
        color: const Color(0xFF43A047),
        unlocked: false,
      ),
    ];
    state = state.copyWith(
      missions: initialMissions,
      badges: state.badges.isEmpty ? initialBadges : state.badges,
      lastReset: DateTime.now(),
    );
  }

  Future<void> _loadFromBackend() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await Future.wait([
        _loadProfile(user.id),
        _loadMissions(user.id),
        _loadBadges(user.id),
      ]);
    } catch (_) {
      // Mantém estado local caso backend falhe; logs podem ser adicionados se necessário.
    }
  }

  Future<void> _loadProfile(String userId) async {
    final response = await _supabase
        .from('gamification_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response != null) {
      state = state.copyWith(
        xpTotal: response['xp_total'] as int? ?? state.xpTotal,
        currentLevel: response['current_level'] as int? ?? state.currentLevel,
        xpNextLevel: response['xp_next_level'] as int? ?? state.xpNextLevel,
        lastReset: DateTime.tryParse(response['last_reset'] as String? ?? '') ?? state.lastReset,
      );
    }
  }

  Future<void> _loadMissions(String userId) async {
    final List<dynamic> response = await _supabase
        .from('gamification_missions')
        .select()
        .eq('user_id', userId);

    if (response.isNotEmpty) {
      final missionMap = {
        for (final mission in state.missions) mission.id: mission,
      };

      for (final data in response) {
        final missionId = data['mission_id'] as String;
        final existing = missionMap[missionId];
        if (existing != null) {
          missionMap[missionId] = existing.copyWith(
            progress: data['progress'] as int? ?? existing.progress,
            status: _statusFromString(data['status'] as String?) ?? existing.status,
          );
        }
      }

      state = state.copyWith(missions: missionMap.values.toList());
    }
  }

  Future<void> _loadBadges(String userId) async {
    final List<dynamic> response = await _supabase
        .from('gamification_badges')
        .select()
        .eq('user_id', userId);

    if (response.isNotEmpty) {
      final badgeMap = {
        for (final badge in state.badges) badge.id: badge,
      };

      for (final data in response) {
        final badgeId = data['badge_id'] as String;
        final existing = badgeMap[badgeId];
        if (existing != null) {
          badgeMap[badgeId] = existing.copyWith(
            unlocked: data['unlocked'] as bool? ?? existing.unlocked,
          );
        }
      }

      state = state.copyWith(badges: badgeMap.values.toList());
    }
  }

  MissionStatus? _statusFromString(String? value) {
    switch (value) {
      case 'completed':
        return MissionStatus.completed;
      case 'locked':
        return MissionStatus.locked;
      case 'inProgress':
        return MissionStatus.inProgress;
    }
    return null;
  }

  void onProductAdded() {
    _ensureWeeklyReset();
    _updateMissionProgress('add_products', increment: 1);
    _updateMissionProgress('stock_manager', increment: 1);
    _logEvent(
      type: 'product_added',
      title: 'Produto adicionado',
      description: 'Novo item cadastrado na despensa',
    );
  }

  void onProductConsumed({required bool isCritical}) {
    _ensureWeeklyReset();
    _updateMissionProgress('sustainable_eater', increment: 1);
    // Atualiza missões relacionadas a produtos críticos
    _updateMissionProgress('consume_critical', increment: isCritical ? 1 : 0);
    if (isCritical) {
      _updateMissionProgress('critical_rescuer', increment: 1);
    }
    _logEvent(
      type: 'product_consumed',
      title: 'Produto consumido',
      description: isCritical
          ? 'Você salvou um item crítico a tempo!'
          : 'Item consumido antes do vencimento',
      metadata: {'critical': isCritical},
    );
  }

  void onRecipeCompleted() {
    _ensureWeeklyReset();
    _updateMissionProgress('complete_recipe', increment: 1);
    _updateMissionProgress('recipe_master', increment: 1);
    _logEvent(
      type: 'recipe_completed',
      title: 'Receita concluída',
      description: 'Uma receita foi concluída com sucesso',
    );
  }

  void onProductDiscarded() {
    _ensureWeeklyReset();
    _updateMissionProgress('zero_waste', increment: 1);
    _updateMissionProgress('waste_tracker', increment: 1);
    _logEvent(
      type: 'product_discarded',
      title: 'Descarte registrado',
      description: 'Produto descartado conscientemente',
    );
  }

  void _ensureWeeklyReset() {
    final now = DateTime.now();
    final lastReset = state.lastReset;
    final needsReset = now.difference(lastReset).inDays >= 7 ||
        (now.weekday == DateTime.monday && lastReset.weekday != DateTime.monday);

    if (needsReset) {
      resetWeeklyMissions();
    }
  }

  void _updateMissionProgress(String missionId, {required int increment}) {
    if (increment == 0) return;

    final userId = _supabase.auth.currentUser?.id;
    final previousLevel = state.currentLevel;
    final previousXp = state.xpTotal;
    final List<String> newlyCompleted = [];
    int xpGained = 0;
    GamificationMission? persistedMission;

    final updatedMissions = state.missions.map((mission) {
      if (mission.id != missionId) {
        return mission;
      }

      if (mission.isCompleted) {
        persistedMission = mission;
        return mission;
      }

      final updatedProgress = (mission.progress + increment).clamp(0, mission.goal);
      final isNowCompleted = updatedProgress >= mission.goal;

      if (isNowCompleted && !mission.isCompleted) {
        newlyCompleted.add(mission.id);
        xpGained += mission.xpReward;
      }

      final updatedMission = mission.copyWith(
        progress: updatedProgress,
        status: isNowCompleted ? MissionStatus.completed : mission.status,
      );
      persistedMission = updatedMission;
      return updatedMission;
    }).toList();

    if (xpGained == 0 && newlyCompleted.isEmpty) {
      state = state.copyWith(missions: updatedMissions);
      return;
    }

    int newXp = state.xpTotal + xpGained;
    int newLevel = state.currentLevel;
    int nextThreshold = state.xpNextLevel;
    while (newXp >= nextThreshold) {
      newXp -= nextThreshold;
      newLevel++;
      nextThreshold += 150;
    }

    state = state.copyWith(
      missions: updatedMissions,
      xpTotal: newXp,
      currentLevel: newLevel,
      xpNextLevel: nextThreshold,
      recentlyCompletedMissions: newlyCompleted,
      lastXpGained: xpGained,
    );

    if (newlyCompleted.isNotEmpty) {
      unlockBadge('first_mission');
    }

    final zeroWaste = updatedMissions.firstWhere(
      (m) => m.id == 'zero_waste',
      orElse: () => const GamificationMission(
        id: '',
        title: '',
        description: '',
        progress: 0,
        goal: 0,
        xpReward: 0,
      ),
    );
    if (zeroWaste.id == 'zero_waste' && zeroWaste.isCompleted) {
      unlockBadge('no_waste_week');
    }

    if (userId != null && persistedMission != null) {
      unawaited(_persistProfile(userId));
      unawaited(_persistMissionProgress(userId, missionId, persistedMission!));
    }

    if (newlyCompleted.isNotEmpty) {
      for (final id in newlyCompleted) {
        final completedMission = updatedMissions.firstWhere(
          (m) => m.id == id,
          orElse: () => persistedMission!,
        );
        _logEvent(
          type: 'mission_completed',
          title: 'Missão concluída',
          description: completedMission.title,
          xpChange: completedMission.xpReward,
          metadata: {
            'missionId': completedMission.id,
            'goal': completedMission.goal,
          },
        );
      }
    }

    if (xpGained > 0) {
      final xpDelta = state.xpTotal - previousXp;
      if (xpDelta > 0 && newlyCompleted.isEmpty) {
        _logEvent(
          type: 'xp_gained',
          title: 'XP ganho',
          description: 'Você recebeu $xpDelta XP',
          xpChange: xpDelta,
        );
      }
    }

    if (state.currentLevel > previousLevel) {
      _logEvent(
        type: 'level_up',
        title: 'Novo nível alcançado',
        description: 'Você agora é nível ${state.currentLevel}',
      );
    }
  }

  void resetWeeklyMissions([List<GamificationMission>? newMissions]) {
    final userId = _supabase.auth.currentUser?.id;
    if (newMissions == null) {
      state = state.copyWith(
        missions: _defaultMissions(),
        recentlyCompletedMissions: const [],
        lastXpGained: 0,
        lastReset: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        missions: newMissions,
        recentlyCompletedMissions: const [],
        lastXpGained: 0,
        lastReset: DateTime.now(),
      );
    }

    if (userId != null) {
      unawaited(_persistProfile(userId));
      unawaited(_persistAllMissions(userId, state.missions));
    }
  }

  void unlockBadge(String badgeId) {
    final userId = _supabase.auth.currentUser?.id;
    List<GamificationBadge> updatedBadges = state.badges.map((badge) {
      if (badge.id == badgeId) {
        return badge.copyWith(unlocked: true);
      }
      return badge;
    }).toList();
    state = state.copyWith(badges: updatedBadges);

    if (userId != null) {
      unawaited(_persistBadge(userId, badgeId, unlocked: true));
    }

    final unlockedBadge = updatedBadges.firstWhere(
      (badge) => badge.id == badgeId,
      orElse: () => updatedBadges.first,
    );
    _logEvent(
      type: 'badge_unlocked',
      title: 'Badge desbloqueada',
      description: unlockedBadge.title,
      metadata: {'badgeId': badgeId},
    );
  }

  void clearRecentMissionEvents() {
    if (state.recentlyCompletedMissions.isEmpty && state.lastXpGained == 0) {
      return;
    }
    state = state.copyWith(
      recentlyCompletedMissions: const [],
      lastXpGained: 0,
    );
  }

  Future<void> _persistProfile(String userId) async {
    try {
      await _supabase.from('gamification_profiles').upsert({
        'user_id': userId,
        'xp_total': state.xpTotal,
        'current_level': state.currentLevel,
        'xp_next_level': state.xpNextLevel,
        'last_reset': state.lastReset.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _persistMissionProgress(
    String userId,
    String missionId,
    GamificationMission mission,
  ) async {
    try {
      await _supabase.from('gamification_missions').upsert({
        'user_id': userId,
        'mission_id': missionId,
        'progress': mission.progress,
        'status': mission.status.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _persistAllMissions(String userId, List<GamificationMission> missions) async {
    try {
      final payload = missions
          .map((mission) => {
                'user_id': userId,
                'mission_id': mission.id,
                'progress': mission.progress,
                'status': mission.status.name,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
          .toList();

      if (payload.isNotEmpty) {
        await _supabase.from('gamification_missions').upsert(payload);
      }
    } catch (_) {}
  }

  Future<void> _persistBadge(String userId, String badgeId,
      {required bool unlocked}) async {
    try {
      await _supabase.from('gamification_badges').upsert({
        'user_id': userId,
        'badge_id': badgeId,
        'unlocked': unlocked,
        'unlocked_at': unlocked ? DateTime.now().toUtc().toIso8601String() : null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  void _logEvent({
    required String type,
    required String title,
    String? description,
    int xpChange = 0,
    Map<String, dynamic>? metadata,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final baseMetadata = {
      'device': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      },
    };
    final mergedMetadata = {...baseMetadata, ...?metadata};

    unawaited(_eventService.logEvent(
      userId: userId,
      eventType: type,
      title: title,
      description: description,
      xpChange: xpChange,
      metadata: mergedMetadata,
    ));
  }
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) => GamificationNotifier());
