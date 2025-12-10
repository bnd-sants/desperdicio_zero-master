import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget que mostra indicador visual quando receitas são carregadas do cache
class RecipeCacheIndicator extends StatelessWidget {
  final Widget child;
  final String cacheKey;

  const RecipeCacheIndicator({
    super.key,
    required this.child,
    required this.cacheKey,
  });

  Future<bool> _isCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(cacheKey);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isCached(),
      builder: (context, snapshot) {
        final isCached = snapshot.data ?? false;
        
        return Stack(
          children: [
            child,
            if (isCached)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(76, 175, 80, 0.9), // Colors.green com opacidade 0.9
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.offline_bolt,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Cache',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Widget para mostrar estatísticas de cache
class CacheStatsWidget extends StatelessWidget {
  const CacheStatsWidget({super.key});

  Future<Map<String, int>> _getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int meals = 0;
      int searches = 0;
      int categories = 0;
      int random = 0;
      
      for (final key in keys) {
        if (key.startsWith('meal_')) meals++;
        if (key.startsWith('search_')) searches++;
        if (key.startsWith('categories')) categories++;
        if (key.startsWith('random_meal')) random++;
      }
      
      return {
        'meals': meals,
        'searches': searches,
        'categories': categories,
        'random': random,
      };
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getCacheStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final stats = snapshot.data!;
        final total = stats.values.fold(0, (sum, val) => sum + val);
        
        if (total == 0) {
          return const SizedBox.shrink();
        }
        
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Cache de Receitas',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatRow('Receitas individuais', stats['meals'] ?? 0),
                _buildStatRow('Buscas salvas', stats['searches'] ?? 0),
                _buildStatRow('Categorias', stats['categories'] ?? 0),
                _buildStatRow('Receita aleatória', stats['random'] ?? 0),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: $total itens em cache',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Icon(
                      Icons.offline_bolt,
                      color: Colors.green,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(33, 150, 243, 0.1), // Colors.blue com opacidade 0.1
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
