import 'package:flutter/material.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/models/gamification_models.dart';

class GamificationXpHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int level;
  final int xpCurrent;
  final int xpNextLevel;

  const GamificationXpHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.xpCurrent,
    required this.xpNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = xpNextLevel == 0
        ? 0.0
        : (xpCurrent / xpNextLevel).clamp(0.0, 1.0).toDouble();

    return AppCard(
      gradient: StyleTokens.heroGradient(
        colorScheme.primary,
        colorScheme.primaryContainer,
      ),
      padding: const EdgeInsets.all(StyleTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: StyleTokens.spacingXS),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.85),
                ),
          ),
          const SizedBox(height: StyleTokens.spacingM),
          Row(
            children: [
              Chip(
                backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
                label: Text(
                  'Nível $level',
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
              const Spacer(),
              Text(
                '$xpCurrent / $xpNextLevel XP',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: StyleTokens.spacingS),
          ClipRRect(
            borderRadius: BorderRadius.circular(StyleTokens.radiusPill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class MissionCard extends StatelessWidget {
  final GamificationMission mission;
  final bool highlight;

  const MissionCard({
    super.key,
    required this.mission,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final statusColor = _statusColor(colorScheme, mission.status);

    return AnimatedScale(
      scale: highlight ? 1.03 : 1,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 220),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppCard(
            color: highlight
                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                : null,
            elevated: true,
            padding: const EdgeInsets.all(StyleTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Icon(mission.icon, color: statusColor),
                    ),
                    const SizedBox(width: StyleTokens.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            mission.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text('+${mission.xpReward} XP'),
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                const SizedBox(height: StyleTokens.spacingM),
                LinearProgressIndicator(
                  value: mission.completionRatio,
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
                const SizedBox(height: StyleTokens.spacingXS),
                Row(
                  children: [
                    Text(
                      '${mission.progress}/${mission.goal}',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      mission.isCompleted ? 'Completa' : 'Em progresso',
                      style:
                          theme.textTheme.labelSmall?.copyWith(color: statusColor),
                    ),
                  ],
                ),
                if (highlight) ...[
                  const SizedBox(height: StyleTokens.spacingS),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: statusColor,
                      ),
                      const SizedBox(width: StyleTokens.spacingXS),
                      Text(
                        'Concluída recentemente',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (highlight)
            Positioned(
              top: -10,
              right: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(StyleTokens.radiusM),
                  boxShadow: [StyleTokens.mediumShadow],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StyleTokens.spacingS,
                    vertical: StyleTokens.spacingXS,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Nova conquista',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(ColorScheme colorScheme, MissionStatus status) {
    switch (status) {
      case MissionStatus.completed:
        return colorScheme.primary;
      case MissionStatus.locked:
        return colorScheme.outline;
      case MissionStatus.inProgress:
        return colorScheme.secondary;
    }
  }
}

class BadgeGrid extends StatelessWidget {
  final List<GamificationBadge> badges;

  const BadgeGrid({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conquistas',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: StyleTokens.spacingM),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: StyleTokens.spacingM,
              crossAxisSpacing: StyleTokens.spacingM,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        badge.unlocked ? badge.color.withValues(alpha: 0.15) : colorScheme.surface,
                    child: Icon(
                      badge.icon,
                      color: badge.unlocked
                          ? badge.color
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: StyleTokens.spacingXS),
                  Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
