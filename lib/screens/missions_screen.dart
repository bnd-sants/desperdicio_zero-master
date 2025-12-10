import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/gamification_provider.dart';
import 'package:desperdicio_zero/widgets/gamification_widgets.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missões'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(StyleTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GamificationXpHeader(
              title: 'Seu Progresso',
              subtitle: 'Complete missões para ganhar XP!',
              level: gamification.currentLevel,
              xpCurrent: gamification.xpTotal,
              xpNextLevel: gamification.xpNextLevel,
            ),
            const SizedBox(height: StyleTokens.spacingL),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Missões Ativas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: StyleTokens.spacingM),
                  ...gamification.missions.map(
                    (mission) => Padding(
                      padding: const EdgeInsets.only(bottom: StyleTokens.spacingM),
                      child: MissionCard(mission: mission),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
