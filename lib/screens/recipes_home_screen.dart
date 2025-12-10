import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/recipe_model.dart';
import 'package:desperdicio_zero/core/providers/services/external_recipe_provider.dart';
import 'package:desperdicio_zero/widgets/eating_loader.dart';
import 'recipe_detail_screen.dart';

class RecipeSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  RecipeSearchDelegate({required this.ref});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(query);
  }

  Widget _buildSearchResults(String searchQuery) {
    if (searchQuery.isEmpty) {
      return const Center(
        child: Text('Digite para buscar receitas'),
      );
    }

    final recipesAsync = ref.watch(recipeSuggestionsProvider(searchQuery));

    return recipesAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return const Center(
            child: Text('Nenhuma receita encontrada'),
          );
        }

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            return ListTile(
              leading: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.restaurant_menu),
              title: Text(recipe.title),
              subtitle: recipe.prepTime != null
                  ? Text('${recipe.prepTime} min')
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(
                      recipeId: int.tryParse(recipe.id) ?? 0,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Erro ao buscar receitas: $error'),
      ),
    );
  }
}

class RecipesHomeScreen extends ConsumerStatefulWidget {
  const RecipesHomeScreen({super.key});

  @override
  ConsumerState<RecipesHomeScreen> createState() => _RecipesHomeScreenState();
}

class _RecipesHomeScreenState extends ConsumerState<RecipesHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedIngredients = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreRecipes();
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    // No Gemini, a paginação pode ser implementada no próprio serviço se necessário
    // Por enquanto, apenas marcamos que não há mais itens para carregar
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _showAddIngredientDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar Ingrediente'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome do ingrediente',
              hintText: 'Ex: Tomate, Cebola, Frango',
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {
                  _selectedIngredients.add(value.trim());
                });
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _selectedIngredients.add(controller.text.trim());
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    // Verifica se o erro é devido à falta de chave da API
    final errorMessage = error.toString().toLowerCase();
    final isApiKeyError = errorMessage.contains('api key') || 
                        errorMessage.contains('chave da api') ||
                        errorMessage.contains('spoonacular');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApiKeyError ? Icons.vpn_key_off : Icons.error_outline, 
              size: 64, 
              color: isApiKeyError ? Colors.orange : Colors.red
            ),
            const SizedBox(height: 16),
            Text(
              isApiKeyError ? 'Chave da API não configurada' : 'Erro ao carregar receitas',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isApiKeyError 
                ? 'Para ver sugestões de receitas personalizadas, você precisa configurar uma chave da API do Spoonacular.'
                : 'Verifique sua conexão com a internet e tente novamente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (isApiKeyError) ...[
              const Text(
                'Como configurar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Acesse spoonacular.com/food-api\n2. Crie uma conta gratuita\n3. Obtenha sua chave de API\n4. Adicione ao arquivo .env:\n   SPOONACULAR_API_KEY=sua_chave_aqui',
                textAlign: TextAlign.left,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: () async {
                // Tenta carregar receitas de exemplo
                try {
                  final result = await ref.refresh(recipeSuggestionsProvider('example').future);
                  if (result.isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nenhuma receita de exemplo disponível')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao carregar receitas: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(isApiKeyError ? 'Ver receitas de exemplo' : 'Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final key = _selectedIngredients.join(',');
    final recipesAsync = ref.watch(recipeSuggestionsProvider(key.isNotEmpty ? key : 'default'));

    return WillPopScope(
      onWillPop: () async {
        // Permite que o botão de voltar do dispositivo funcione corretamente
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receitas'),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          actions: [
            if (_selectedIngredients.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: 'Limpar ingredientes',
                onPressed: () {
                  setState(() {
                    _selectedIngredients.clear();
                  });
                },
              ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.search, size: 22),
              ),
              tooltip: 'Buscar receitas',
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: RecipeSearchDelegate(ref: ref),
                );
              },
            ),
          ],
        ),
      body: Column(
        children: [
          // Seção de ingredientes selecionados
          if (_selectedIngredients.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _selectedIngredients.map((ingredient) {
                  return Chip(
                    label: Text(ingredient),
                    onDeleted: () {
                      setState(() {
                        _selectedIngredients.remove(ingredient);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
          ],
          // Lista de receitas
          Expanded(
            child: recipesAsync.when(
              data: (List<Recipe> recipes) {
                if (recipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma receita encontrada',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedIngredients.isEmpty
                              ? 'Adicione ingredientes para encontrar receitas'
                              : 'Tente outros ingredientes',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddIngredientDialog(context);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Ingrediente'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: recipes.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= recipes.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Carregando mais receitas...',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final recipe = recipes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailScreen(
                                recipeId: int.tryParse(recipe.id) ?? 0,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Imagem da receita ou placeholder
                            (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
                                ? Image.network(
                                    recipe.imageUrl!,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                                  )
                                : _buildPlaceholderImage(),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
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
                                  if (recipe.prepTime != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 16),
                                          const SizedBox(width: 4),
                                          Text('${recipe.prepTime} min'),
                                        ],
                                      ),
                                    ),
                                  if (recipe.servings != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.people_outline, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${recipe.servings} porções'),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: EatingLoader(
                  loadingText: 'Buscando receitas deliciosas...',
                  size: 200,
                ),
              ),
              error: (error, stack) => _buildErrorWidget(error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIngredientDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Ingrediente'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    ));
  }

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
}
