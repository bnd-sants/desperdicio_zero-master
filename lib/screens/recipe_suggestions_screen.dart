import 'package:flutter/material.dart';
import '../models/spoonacular_models.dart';
import 'package:desperdicio_zero/core/providers/index.dart';
import 'recipe_detail_screen.dart';

class RecipeSuggestionsScreen extends ConsumerWidget {
  final List<String> userIngredients;

  const RecipeSuggestionsScreen({
    super.key,
    required this.userIngredients,
  });
  
  // Widget para exibir quando não há imagem
  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Imagem não disponível', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipeSuggestionsProvider(userIngredients));
    final searchController = TextEditingController();
    String searchQuery = '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas Sugeridas'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar receitas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (value) {
                searchQuery = value.toLowerCase();
                // Atualiza a lista de receitas com base na busca
                ref.invalidate(recipeSuggestionsProvider(userIngredients));
              },
            ),
          ),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar receitas: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(recipeSuggestionsProvider(userIngredients)),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma receita encontrada com seus ingredientes.'),
                  );
                }
                
                // Filtrar receitas com base na busca
                final filteredRecipes = searchQuery.isEmpty
                    ? recipes
                    : recipes.where((recipe) =>
                        recipe.title.toLowerCase().contains(searchQuery)).toList();
                
                if (filteredRecipes.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma receita encontrada com o termo de busca.'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = filteredRecipes[index];
                    return _buildRecipeCard(context, recipe);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, SpoonacularRecipe recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              child: (recipe.image?.isNotEmpty ?? false)
                  ? Image.network(
                      'https://spoonacular.com/recipeImages/${recipe.image}',
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildIngredientInfo(
                        context,
                        'Usados: ${recipe.usedIngredientCount}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildIngredientInfo(
                        context,
                        'Faltam: ${recipe.missedIngredientCount}',
                        Icons.remove_circle,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientInfo(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
