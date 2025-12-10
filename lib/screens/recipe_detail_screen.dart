import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/services/spoonacular_provider.dart';
import '../models/spoonacular_models.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final int recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

Widget _buildNutritionInfo(RecipeDetails recipe) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informação Nutricional'),
          const Text('Informações nutricionais não disponíveis.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    ),
  );
}

  // Widget para exibir quando não há imagem
  static Widget _buildPlaceholderImage() {
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
    final recipeDetailsAsync = ref.watch(recipeDetailsProvider(recipeId));
    final locale = Localizations.localeOf(context);

    // Translate recipe details when they're loaded
    recipeDetailsAsync.whenData((recipe) {
      if (locale.languageCode == 'pt') {
        recipe.translateToPortuguese();
      }
    });

    return PopScope(
  canPop: true,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  },
  child: Scaffold(
    body: recipeDetailsAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando receita...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Não foi possível carregar a receita',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(recipeDetailsProvider(recipeId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (recipe) => CustomScrollView(
            slivers: [
              _buildAppBar(context, recipe),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRecipeInfo(context, recipe),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Ingredientes'),
                      _buildIngredientsList(recipe.extendedIngredients),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Modo de Preparo'),
                      _buildInstructions(recipe.analyzedInstructions),
                      const SizedBox(height: 24),
                      _buildNutritionInfo(recipe),

                      
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, RecipeDetails recipe) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          recipe.title.getText(context),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black54),
            ],
          ),
        ),
        background: recipe.image.isNotEmpty
            ? Hero(
                tag: 'recipe-${recipe.id}',
                child: Image.network(
                  'https://spoonacular.com/recipeImages/${recipe.image}',
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
                ),
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildRecipeInfo(BuildContext context, RecipeDetails recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title.getText(context),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(
              Icons.timer_outlined,
              '${recipe.readyInMinutes} min',
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.people_outline,
              '${recipe.servings} porções',
            ),
            if (recipe.vegetarian) ...[
              const SizedBox(width: 8),
              _buildInfoChip(Icons.eco, 'Vegetariano'),
            ],
            if (recipe.vegan) ...[
              const SizedBox(width: 8),
              _buildInfoChip(Icons.eco, 'Vegano'),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (recipe.summary.en.isNotEmpty)
          Text(
            recipe.summary.getText(context).replaceAll(RegExp(r'<[^>]*>'), ''),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIngredientsList(List<dynamic> ingredients) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: ingredients.map<Widget>((ingredient) {
            return ListTile(
              dense: true,
              leading: const Icon(Icons.check_box_outline_blank, size: 20),
              title: Text(
                '${ingredient['original'] ?? ''}',
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

Widget _buildInstructions(List<dynamic> analyzedInstructions) {
  try {
    debugPrint('=== INÍCIO DAS INSTRUÇÕES ===');
    debugPrint('Tipo de analyzedInstructions: ${analyzedInstructions.runtimeType}');
    debugPrint('analyzedInstructions: $analyzedInstructions');
    
    if (analyzedInstructions.isEmpty) {
      debugPrint('Nenhuma instrução encontrada - Lista vazia');
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Nenhuma instrução disponível.'),
      );
    }

    // Verifica o primeiro item
    final firstInstruction = analyzedInstructions.first;
    debugPrint('Primeira instrução: $firstInstruction');
    debugPrint('Tipo da primeira instrução: ${firstInstruction.runtimeType}');

    // Verifica se tem a chave 'steps'
    if (firstInstruction is! Map || !firstInstruction.containsKey('steps')) {
      debugPrint('Chave "steps" não encontrada ou formato inválido. Tipo: ${firstInstruction.runtimeType}');
      if (firstInstruction is Map) {
        debugPrint('Chaves disponíveis: ${firstInstruction.keys}');
      }
      // Tenta exibir as instruções diretamente se for uma string
      if (firstInstruction is String) {
        return _buildSimpleInstructions([firstInstruction]);
      }
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Formato de instruções não reconhecido.'),
      );
    }

    final steps = firstInstruction['steps'] as List<dynamic>?;
    debugPrint('Passos encontrados: $steps');
    
    if (steps == null || steps.isEmpty) {
      debugPrint('Nenhum passo encontrado nas instruções');
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Nenhuma etapa de preparo disponível.'),
      );
    }

    // Verifica o primeiro passo
    if (steps.isNotEmpty) {
      final firstStep = steps.first;
      debugPrint('Primeiro passo: $firstStep');
      debugPrint('Tipo do primeiro passo: ${firstStep.runtimeType}');
      
      if (firstStep is Map) {
        debugPrint('Chaves do primeiro passo: ${firstStep.keys}');
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            
            debugPrint('--- Passo ${index + 1} ---');
            debugPrint('Tipo do passo: ${step.runtimeType}');
            debugPrint('Conteúdo: $step');
            
            String stepText = 'Passo sem descrição';
            
            if (step is Map) {
              debugPrint('Chaves disponíveis: ${step.keys}');
              if (step.containsKey('step')) {
                stepText = step['step']?.toString().trim() ?? 'Passo sem descrição';
                debugPrint('Texto do passo: $stepText');
              } else if (step.isNotEmpty) {
                // Tenta pegar o primeiro valor se não encontrar a chave 'step'
                stepText = step.values.first?.toString().trim() ?? 'Passo sem descrição';
              }
            } else {
              stepText = step.toString();
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
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
                      stepText,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ ERRO em _buildInstructions: $e');
    debugPrint('Stack trace: $stackTrace');
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('Erro ao carregar as instruções: ${e.toString()}'),
    );
  }
}

// Método auxiliar para exibir instruções simples
Widget _buildSimpleInstructions(List<String> instructions) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
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
                    instruction,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
 }
}
