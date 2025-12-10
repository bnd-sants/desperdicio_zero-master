import 'package:flutter/material.dart';
import 'package:desperdicio_zero/screens/home/home_constants.dart';

class QuickActions extends StatelessWidget {
  final Function(int) onActionSelected;

  const QuickActions({super.key, required this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: HomeConstants.sectionHeaderStyle,
        ),
        const SizedBox(height: HomeConstants.mediumPadding),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: HomeConstants.quickActions.length,
            itemBuilder: (context, index) {
              final action = HomeConstants.quickActions[index];
              return _buildQuickAction(
                context: context,
                icon: action['icon'] as IconData,
                label: action['title'] as String,
                color: action['color'] as Color,
                onTap: () => onActionSelected(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
