import 'package:flutter/material.dart';
import 'package:desperdicio_zero/screens/home/home_constants.dart';

class CategoryChips extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categorias',
          style: HomeConstants.sectionHeaderStyle,
        ),
        const SizedBox(height: HomeConstants.mediumPadding),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: HomeConstants.categories.length,
            itemBuilder: (context, index) {
              final category = HomeConstants.categories[index];
              return _buildCategoryChip(
                icon: category['icon'] as IconData,
                label: category['name'] as String,
                count: category['count'] as int,
                isSelected: selectedIndex == index,
                onTap: () => onCategorySelected(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: HomeConstants.mediumPadding),
        padding: const EdgeInsets.symmetric(
          horizontal: HomeConstants.mediumPadding,
          vertical: HomeConstants.smallPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected ? HomeConstants.primaryColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? HomeConstants.primaryColor : HomeConstants.borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, 
              color: isSelected ? HomeConstants.primaryColor : HomeConstants.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? HomeConstants.primaryColor : HomeConstants.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? HomeConstants.primaryColor : HomeConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : HomeConstants.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
