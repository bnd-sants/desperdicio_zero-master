import 'package:flutter/material.dart';
import '../../models/meal_model.dart';
import '../../theme/app_colors.dart';

class MealDetailScreen extends StatelessWidget {
  final Meal meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (meal.thumbnailUrl != null && meal.thumbnailUrl!.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      meal.thumbnailUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.restaurant_menu, size: 100, color: Colors.grey),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                meal.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (meal.category.isNotEmpty)
                _buildInfoRow(Icons.category, 'Categoria', meal.category),
              if (meal.area.isNotEmpty)
                _buildInfoRow(Icons.location_on, 'Origem', meal.area),
              if (meal.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.label, 'Tags', meal.tags.join(', ')),
              ],
              if (meal.ingredients.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Ingredientes:', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...meal.ingredients.map((ingredient) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Text('• ${ingredient.name} ${ingredient.measure.isNotEmpty ? '(${ingredient.measure})' : ''}'),
                  ),
                ),
              ],
              if (meal.instructions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Modo de Preparo:', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(meal.instructions, textAlign: TextAlign.justify),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 20),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
