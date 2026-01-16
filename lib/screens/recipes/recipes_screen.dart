import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/recipe_model.dart' as model;
import 'package:desperdicio_zero/core/providers/providers.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/widgets/app_text_field.dart';
import 'package:desperdicio_zero/widgets/app_button.dart';
import 'package:desperdicio_zero/widgets/app_snackbar.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';
import 'recipe_detail_screen.dart';

// Alias pra evitar conflito de nomes
typedef Recipe = model.Recipe;

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  late Future<List<Recipe>> _recipesFuture;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  String _searchQuery = '';
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Rápido',
    'Fácil',
    'Saudável',
    'Vegetariano',
    'Sobremesa',
  ];
  final List<String> _quickTags = [
    'Rápido',
    'Fácil',
    'Saudável',
    'Vegetariano',
    'Sobremesa',
  ];

  @override
  void initState() {
    super.initState();
    _recipesFuture = _loadRecipes();
    _searchController.addListener(_onSearchChanged);
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

  Future<List<Recipe>> _loadRecipes() async {
    final recipeService = ref.read(recipeServiceProvider);
    try {
      final recipes = await recipeService.getRecipes();
      // Coleta todas as tags únicas
      final tags = <String>{};
      for (var r in recipes) {
        if (r.tags != null) tags.addAll(r.tags!);
      }
      setState(() {
        _availableTags
          ..clear()
          ..addAll(tags.toList()..sort());
      });
      return recipes;
    } catch (e) {
      debugPrint('Erro ao carregar receitas: $e');
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Não foi possível carregar as receitas.',
        );
      }
      return [];
    }
  }

  bool _matchesSearch(Recipe recipe) {
    // If no search query and no tags selected, show all recipes
    if (_searchQuery.isEmpty && _selectedTags.isEmpty) return true;

    // Check if recipe matches search text
    final matchesSearch =
        _searchQuery.isEmpty ||
        recipe.title.toLowerCase().contains(_searchQuery) ||
        (recipe.description?.toLowerCase().contains(_searchQuery) ?? false) ||
        (recipe.instructions?.toLowerCase().contains(_searchQuery) ?? false) ||
        (recipe.products.any(
          (product) => product.name.toLowerCase().contains(_searchQuery),
        ));

    // If search doesn't match, return false
    if (!matchesSearch) return false;

    // If no tags selected, only apply search filter
    if (_selectedTags.isEmpty) return true;

    // Check if recipe has all selected tags
    return _selectedTags.every((tag) {
      final tagLower = tag.toLowerCase();

      // Check if tag matches any of the recipe's tags
      if (recipe.tags?.any((t) => t.toLowerCase().contains(tagLower)) ??
          false) {
        return true;
      }

      // Special handling for quick tags
      switch (tag) {
        case 'Rápido':
          // Consider a recipe 'Rápido' if prepTime is 30 minutes or less
          return (recipe.prepTime ?? 0) <= 30;

        case 'Fácil':
          // Consider a recipe 'Fácil' if it has few steps or ingredients
          final stepCount =
              recipe.instructions
                  ?.split('\n')
                  .where((s) => s.trim().isNotEmpty)
                  .length ??
              0;
          return stepCount <= 3 || (recipe.products.length <= 5);

        case 'Saudável':
          // Check for health-related keywords in tags or description
          final healthKeywords = [
            'saudável',
            'saudavel',
            'light',
            'fitness',
            'fit',
            'saúde',
            'saude',
          ];
          return healthKeywords.any(
                (keyword) =>
                    recipe.description?.toLowerCase().contains(keyword) ??
                    false,
              ) ||
              (recipe.tags?.any(
                    (t) => healthKeywords.contains(t.toLowerCase()),
                  ) ??
                  false);

        case 'Vegetariano':
          // Check for vegetarian-related keywords
          final vegKeywords = [
            'vegetariano',
            'vegetariana',
            'sem carne',
            'vegetable',
            'veggie',
          ];
          return vegKeywords.any(
            (keyword) =>
                recipe.title.toLowerCase().contains(keyword) ||
                recipe.description?.toLowerCase().contains(keyword) == true ||
                (recipe.tags?.any(
                      (t) => vegKeywords.contains(t.toLowerCase()),
                    ) ??
                    false),
          );

        case 'Sobremesa':
          // Check for dessert-related keywords
          final dessertKeywords = [
            'sobremesa',
            'doce',
            'sobremesas',
            'doces',
            'sobremesa',
            'sobremesas',
            'sobremesa',
            'sobremesas',
          ];
          return dessertKeywords.any(
            (keyword) =>
                recipe.title.toLowerCase().contains(keyword) ||
                recipe.description?.toLowerCase().contains(keyword) == true ||
                (recipe.tags?.any(
                      (t) => dessertKeywords.contains(t.toLowerCase()),
                    ) ??
                    false),
          );

        default:
          // For custom tags, check if they match any part of the recipe
          return recipe.title.toLowerCase().contains(tagLower) ||
              (recipe.description?.toLowerCase().contains(tagLower) ?? false) ||
              (recipe.instructions?.toLowerCase().contains(tagLower) ??
                  false) ||
              (recipe.products.any(
                (p) => p.name.toLowerCase().contains(tagLower),
              ));
      }
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();

        // Add to quick tags if not already there
        if (!_quickTags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
          _quickTags.add(tag);
        }
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _selectedTags.remove(tag));
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.fastfood, size: 64, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receitas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _recipesFuture = _loadRecipes();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(StyleTokens.spacingL),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _searchController,
                      label: 'Buscar receitas',
                      hint: 'Pesquisar receitas...',
                      prefixIcon: const Icon(Icons.search),
                      textInputAction: TextInputAction.search,
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _tagController,
                            label: 'Palavra-chave',
                            hint: 'Ex.: bolo, rápido',
                            prefixIcon: const Icon(Icons.sell_outlined),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: StyleTokens.spacingM),
                        FilledButton.icon(
                          onPressed: _addTag,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: StyleTokens.spacingL,
                              vertical: StyleTokens.spacingS,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                StyleTokens.radiusM,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_quickTags.isNotEmpty) ...[
                      const SizedBox(height: StyleTokens.spacingL),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quickTags.map((tag) {
                            final isSelected = _selectedTags.contains(tag);
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: StyleTokens.spacingS,
                              ),
                              child: FilterChip(
                                label: Text(tag),
                                selected: isSelected,
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
                                selectedColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                checkmarkColor: theme.colorScheme.primary,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodyMedium?.color,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    if (_selectedTags.isNotEmpty) ...[
                      const SizedBox(height: StyleTokens.spacingM),
                      Wrap(
                        spacing: StyleTokens.spacingS,
                        runSpacing: StyleTokens.spacingS,
                        children: _selectedTags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => _removeTag(tag),
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.08),
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Recipe>>(
                future: _recipesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(StyleTokens.spacingL),
                        child: AppCard(
                          elevated: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Erro ao carregar receitas.'),
                              const SizedBox(height: StyleTokens.spacingM),
                              AppButton(
                                text: 'Tentar novamente',
                                onPressed: () {
                                  setState(() {
                                    _recipesFuture = _loadRecipes();
                                  });
                                },
                                isFullWidth: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final recipes = snapshot.data ?? [];
                  final filtered = recipes
                      .where((r) => _matchesSearch(r))
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(StyleTokens.spacingL),
                        child: AppCard(
                          elevated: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Nenhuma receita encontrada.'),
                              const SizedBox(height: StyleTokens.spacingM),
                              AppButton(
                                text: 'Limpar filtros',
                                onPressed: () {
                                  setState(() {
                                    _selectedTags.clear();
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                                isFullWidth: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      left: StyleTokens.spacingL,
                      right: StyleTokens.spacingL,
                      top: StyleTokens.spacingS,
                      bottom: StyleTokens.spacingXL,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _buildRecipeCard(context, filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    final theme = Theme.of(context);

    return AppCard(
      margin: const EdgeInsets.only(bottom: StyleTokens.spacingL),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(StyleTokens.radiusL),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipe: recipe),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(StyleTokens.radiusL),
                topRight: Radius.circular(StyleTokens.radiusL),
              ),
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? Image.network(
                      recipe.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(StyleTokens.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: StyleTokens.spacingS),
                  Text(
                    recipe.description ?? 'Sem descrição',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: StyleTokens.spacingM),
                  Wrap(
                    spacing: StyleTokens.spacingS,
                    runSpacing: StyleTokens.spacingS,
                    children: [
                      if (recipe.prepTime != null)
                        Chip(
                          label: Text('${recipe.prepTime} min'),
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      if (recipe.servings != null)
                        Chip(
                          label: Text('${recipe.servings} porções'),
                          backgroundColor: theme.colorScheme.secondary
                              .withValues(alpha: 0.1),
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
}
