import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/recipe_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:desperdicio_zero/core/providers/gamification_provider.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final Recipe recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com imagem da receita
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: recipe.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: recipe.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 50),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 50),
                    ),
            ),
          ),
          // Conteúdo da receita
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações básicas
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('${recipe.prepTime} min'),
                      const SizedBox(width: 20),
                      Icon(Icons.people, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('${recipe.servings} porções'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Ingredientes
                  Text(
                    'Ingredientes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...recipe.products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${product.quantity} ${product.unit} - ${product.name}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Modo de preparo
                  Text(
                    'Modo de Preparo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...(recipe.instructions?.split('\n').where((s) => s.trim().isNotEmpty).toList() ?? []).asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.trim(),
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(gamificationProvider.notifier).onRecipeCompleted();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receita concluída! +80 XP'),
              backgroundColor: Colors.green,
            ),
          );
        },
        icon: const Icon(Icons.check),
        label: const Text('Concluir Receita'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// Função para navegar para a tela de detalhes
void navigateToRecipeDetail(BuildContext context, Recipe recipe) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => RecipeDetailScreen(recipe: recipe),
    ),
  );
}
