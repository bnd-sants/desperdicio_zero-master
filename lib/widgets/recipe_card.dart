import 'package:flutter/material.dart';
import 'package:desperdicio_zero/models/recipe_model.dart' as model;

// Create a type alias for the Recipe model
typedef Recipe = model.Recipe;

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final bool isFavorite;
  final Function(bool)? onFavoriteToggle;
  final int availableIngredients;
  final int totalIngredients;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.availableIngredients = 0,
    this.totalIngredients = 0,
  });

  // Calculate total cooking time (prep + cook time)
  int? get _totalCookingTime {
    if (recipe.prepTime == null && recipe.cookTime == null) return null;
    return (recipe.prepTime ?? 0) + (recipe.cookTime ?? 0);
  }

  // Format preparation time
  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return 'Tempo não informado';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h${remainingMinutes > 0 ? ' ${remainingMinutes}min' : ''}';
  }

  // Get serving text
  String _getServingText() {
    if (recipe.servings == null || recipe.servings! <= 0) return '';
    return '${recipe.servings} ${recipe.servings == 1 ? 'porção' : 'porções'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalIngredients > 0 ? availableIngredients / totalIngredients : 0.0;
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;
    final cookingTime = _formatDuration(_totalCookingTime);
    final servings = _getServingText();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipe Image
            if (hasImage)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(recipe.imageUrl!), 
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 150,
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
              ),
            
            // Recipe Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Favorite Button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onFavoriteToggle != null)
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                          ),
                          onPressed: () => onFavoriteToggle!(!isFavorite),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Cooking Time and Servings
                  Row(
                    children: [
                      if (cookingTime.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              cookingTime,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      
                      if (cookingTime.isNotEmpty && servings.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('•', style: TextStyle(color: Colors.grey)),
                        ),
                      
                      if (servings.isNotEmpty)
                        Text(
                          servings,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  
                  // Description (if available)
                  if (recipe.description?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(
                      recipe.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Progress bar for available ingredients
                  if (totalIngredients > 0) ...[
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ingredientes disponíveis',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              '$availableIngredients/$totalIngredients',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 
                                ? Colors.green 
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
