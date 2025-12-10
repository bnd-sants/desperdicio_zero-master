import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/recipe_model.dart' as model;
import 'package:desperdicio_zero/core/providers/providers.dart';
import 'recipe_detail_screen.dart';

typedef Recipe = model.Recipe;

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({Key? key}) : super(key: key);

  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  late Future<List<Recipe>> _recipesFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadRecipes() async {
    try {
      final recipeService = ref.read(recipeServiceProvider);
      setState(() {
        _recipesFuture = recipeService.getRecipes().then((recipes) {
          // Extract all unique tags from recipes
          final tags = <String>{};
          for (var recipe in recipes) {
            if (recipe.tags != null) {
              tags.addAll(recipe.tags!);
            }
          }
          _availableTags.clear();
          _availableTags.addAll(tags.toList()..sort());
          return recipes;
        });
      });
    } catch (e) {
      debugPrint('Error loading recipes: $e');
      rethrow;
    }
  }

  bool _matchesSearch(Recipe recipe) {
    if (_searchQuery.isEmpty && _selectedTags.isEmpty) return true;
    
    // Check title, description, and instructions
    final matchesSearch = _searchQuery.isEmpty ||
        recipe.title.toLowerCase().contains(_searchQuery) ||
        (recipe.description?.toLowerCase().contains(_searchQuery) ?? false) ||
        (recipe.instructions?.toLowerCase().contains(_searchQuery) ?? false);
    
    // Check products/ingredients
    final matchesIngredients = _searchQuery.isEmpty ||
        recipe.products.any((product) => 
            product.name.toLowerCase().contains(_searchQuery));
    
    // Check tags
    final matchesTags = _selectedTags.isEmpty || 
        (_selectedTags.every((tag) => 
            recipe.tags?.any((t) => t.toLowerCase().contains(tag.toLowerCase())) ?? false));
    
    return matchesSearch || matchesIngredients && matchesTags;
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(
        Icons.fastfood,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe, bool isDarkMode) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipe image
            recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                ? Image.network(
                    recipe.imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
            
            // Recipe info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description ?? '',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (recipe.prepTime != null)
                        Chip(
                          label: Text(
                            '${recipe.prepTime} min',
                            style: theme.textTheme.bodySmall,
                          ),
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      if (recipe.servings != null)
                        Chip(
                          label: Text(
                            '${recipe.servings} porções',
                            style: theme.textTheme.bodySmall,
                          ),
                          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ...?recipe.tags?.map((tag) => Chip(
                        label: Text(
                          tag,
                          style: theme.textTheme.bodySmall,
                        ),
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      )).toList(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecipes,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar receitas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Tag input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Adicionar palavra-chave (ex: bolo, rápido, etc)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 32),
                  onPressed: _addTag,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          
          // Selected tags
          if (_selectedTags.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: _selectedTags.length,
                itemBuilder: (context, index) {
                  final tag = _selectedTags[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(tag),
                    ),
                  );
                },
              ),
            ),
          
          // Available tags
          if (_availableTags.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: _availableTags.length,
                itemBuilder: (context, index) {
                  final tag = _availableTags[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (!_selectedTags.contains(tag)) {
                              _selectedTags.add(tag);
                            }
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          
          const Divider(height: 1),
          
          // Recipe list
          Expanded(
            child: FutureBuilder<List<Recipe>>(
              future: _recipesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar receitas',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRecipes,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                final recipes = snapshot.data ?? [];
                final filteredRecipes = recipes.where(_matchesSearch).toList();

                if (filteredRecipes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedTags.isNotEmpty
                              ? 'Nenhuma receita encontrada com os critérios de busca'
                              : 'Nenhuma receita encontrada',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty || _selectedTags.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedTags.clear();
                                _searchQuery = '';
                              });
                            },
                            child: const Text('Limpar busca'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = filteredRecipes[index];
                    return _buildRecipeCard(context, recipe, isDarkMode);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
