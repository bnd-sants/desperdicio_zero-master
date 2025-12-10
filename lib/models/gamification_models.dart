import 'package:flutter/material.dart';

enum MissionStatus { inProgress, completed, locked }

class GamificationMission {
  final String id;
  final String title;
  final String description;
  final int progress;
  final int goal;
  final int xpReward;
  final MissionStatus status;
  final IconData icon;

  const GamificationMission({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.goal,
    required this.xpReward,
    this.status = MissionStatus.inProgress,
    this.icon = Icons.emoji_events_outlined,
  });

  double get completionRatio => goal == 0 ? 0 : (progress / goal).clamp(0, 1);

  bool get isCompleted => status == MissionStatus.completed || progress >= goal;

  GamificationMission copyWith({
    String? id,
    String? title,
    String? description,
    int? progress,
    int? goal,
    int? xpReward,
    MissionStatus? status,
    IconData? icon,
  }) {
    return GamificationMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      progress: progress ?? this.progress,
      goal: goal ?? this.goal,
      xpReward: xpReward ?? this.xpReward,
      status: status ?? this.status,
      icon: icon ?? this.icon,
    );
  }
}

class GamificationBadge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;

  const GamificationBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.unlocked = false,
  });

  GamificationBadge copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    bool? unlocked,
  }) {
    return GamificationBadge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}
