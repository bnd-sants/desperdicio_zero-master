import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import 'package:desperdicio_zero/core/providers/products/product_provider.dart';
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' as logger;
import '../calendar_screen.dart';
import '../profile_screen.dart';
import '../statistics_screen.dart';
import 'package:desperdicio_zero/widgets/fridge_heatmap.dart';
import 'package:desperdicio_zero/widgets/gamification_widgets.dart';
import 'package:desperdicio_zero/core/providers/gamification_provider.dart';
import 'package:desperdicio_zero/models/gamification_models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

String _resolveUserName(AuthState authState) {
  logger.logDebug('Estado de autenticação: $authState');

  if (authState is Authenticated) {
    logger.logDebug('Usuário autenticado: ${authState.user.id}');
    final trimmedName = authState.fullName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      final firstName = trimmedName.split(' ').first;
      logger.logDebug('Nome do usuário: $firstName');
      return firstName;
    }

    final emailPrefix = authState.user.email?.split('@').first;
    if (emailPrefix != null && emailPrefix.isNotEmpty) {
      logger.logDebug('Usando email como nome: $emailPrefix');
      return emailPrefix;
    }

    logger.logWarning('Nenhum nome ou email disponível');
    return 'Usuário';
  }

  if (authState is AuthLoading) {
    logger.logInfo('Carregando dados do usuário...');
    return '...';
  }

  if (authState is AuthError) {
    logger.logError('Erro ao carregar usuário: ${authState.message}');
    return 'Usuário';
  }

  if (authState is Unauthenticated) {
    logger.logWarning('Usuário não autenticado');
    return 'Usuário';
  }

  logger.logDebug('Estado inicial de autenticação');
  return '...';
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenGamificationEvents();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _listenGamificationEvents() {
    ref.listen<GamificationState>(
      gamificationProvider,
      (previous, next) {
        if (!mounted) return;
        if (next.recentlyCompletedMissions.isEmpty || next.lastXpGained == 0) {
          return;
        }

        final missionNames = next.recentlyCompletedMissions
            .map((id) {
              final mission = next.missions.firstWhere(
                (mission) => mission.id == id,
                orElse: () => const GamificationMission(
                  id: 'mission',
                  title: 'Missão',
                  description: '',
                  progress: 0,
                  goal: 0,
                  xpReward: 0,
                ),
              );
              return mission.title;
            })
            .join(', ');

        final message = next.recentlyCompletedMissions.length > 1
            ? 'Missões $missionNames concluídas! +${next.lastXpGained} XP'
            : 'Missão $missionNames concluída! +${next.lastXpGained} XP';

        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Ver missões',
                onPressed: () {
                  Navigator.of(context).pushNamed('/missions');
                },
              ),
            ),
          );

        ref.read(gamificationProvider.notifier).clearRecentMissionEvents();
      },
    );
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildCurrentScreen() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (mounted) {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHomeContent(),
        const CalendarScreen(),
        const StatisticsScreen(),
        const ProfileScreen(),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return AppCard(
      color: colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(
        vertical: StyleTokens.spacingXXL,
        horizontal: StyleTokens.spacingXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: colorScheme.primary.withValues(alpha: 0.6)),
          const SizedBox(height: StyleTokens.spacingL),
          Text(
            'Nenhum produto ainda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: StyleTokens.spacingS),
          Text(
            'Cadastre seus itens para acompanhar vencimentos e impacto positivo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: StyleTokens.spacingXL),
          FilledButton.icon(
            onPressed: _navigateToAddProduct,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar primeiro produto'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products,
      {bool embedded = false, ColorScheme? colorScheme}) {
    final filteredProducts = _searchQuery.isEmpty
        ? products
        : products
            .where((product) => product.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    if (filteredProducts.isEmpty) {
      return _buildEmptyState(colorScheme ?? Theme.of(context).colorScheme);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: StyleTokens.spacingS),
      shrinkWrap: embedded,
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: StyleTokens.spacingL,
        mainAxisSpacing: StyleTokens.spacingL,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/product-detail',
              arguments: product,
            );
          },
          onLongPress: () {
            _showProductOptions(product);
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shopping_basket,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantidade: ${product.quantity} ${product.unit}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (product.expirationDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Validade: ${DateFormat('dd/MM/yyyy').format(product.expirationDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.isExpired ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.pushNamed(
      context,
      '/add-product',
    );

    if (result == true) {
      // Refresh the products list if needed
      ref.invalidate(productsProvider);
    }
  }

  void _showProductOptions(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.restaurant),
            title: const Text('Marcar como consumido'),
            onTap: () async {
              Navigator.pop(context);
              try {
                await ref.read(productsProvider.notifier).markAsConsumed(product.id);
                ref.read(gamificationProvider.notifier).onProductConsumed(isCritical: product.isCritical);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Produto consumido! ${product.isCritical ? '+120 XP' : '+15 XP'}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao consumir produto'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/add-product',
                arguments: product,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Excluir', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/add-product',
                arguments: {'product': product, 'deleteMode': true},
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final productState = ref.watch(productsProvider);
    return productState.when(
      data: (products) => _buildHubContent(products),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (errorMessage) => Center(child: Text('Erro: $errorMessage')),
    );
  }

  Widget _buildHubContent(List<Product> products) {
    final colorScheme = Theme.of(context).colorScheme;
    final metrics = _HomeMetrics.fromProducts(products);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        StyleTokens.spacingL,
        StyleTokens.spacingL,
        StyleTokens.spacingL,
        StyleTokens.spacingXL,
      ),
      children: [
        _buildHeroCard(metrics, colorScheme),
        const SizedBox(height: StyleTokens.spacingL),
        Consumer(
          builder: (context, ref, _) {
            final gamification = ref.watch(gamificationProvider);
            return GamificationXpHeader(
              title: 'Seu Progresso',
              subtitle: 'Complete missões para ganhar XP!',
              level: gamification.currentLevel,
              xpCurrent: gamification.xpTotal,
              xpNextLevel: gamification.xpNextLevel,
            );
          },
        ),
        const SizedBox(height: StyleTokens.spacingL),
        FridgeHeatmapSection(products: products),
        const SizedBox(height: StyleTokens.spacingL),
        _buildQuickActions(colorScheme),
        const SizedBox(height: StyleTokens.spacingL),
        _buildSearchBar(),
        const SizedBox(height: StyleTokens.spacingM),
        _buildSectionHeader('Seus produtos'),
        const SizedBox(height: StyleTokens.spacingS),
        _buildProductGrid(
          products,
          embedded: true,
          colorScheme: colorScheme,
        ),
      ],
    );
  }


  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StyleTokens.radiusPill),
        boxShadow: [
          if (!isDark) StyleTokens.lightShadow,
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Buscar produtos...',
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          prefixIcon:
              Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(StyleTokens.radiusPill),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor:
              isDark ? theme.cardColor.withValues(alpha: 0.7) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _navigateToAddProduct(),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Adicionar'),
        ),
      ],
    );
  }

  Widget _buildHeroCard(_HomeMetrics metrics, ColorScheme colorScheme) {
    return AppCard(
      gradient: StyleTokens.heroGradient(
        colorScheme.primary,
        colorScheme.primaryContainer,
      ),
      borderRadius: BorderRadius.circular(StyleTokens.radiusXXL),
      padding: const EdgeInsets.all(StyleTokens.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de hoje',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metrics.criticalItems > 0
                ? 'Você tem ${metrics.criticalItems} itens para cuidar nos próximos dias.'
                : 'Tudo em dia! Nenhum item crítico no momento.',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(
                label: 'Itens ativos',
                value: metrics.totalItems,
                color: colorScheme.onPrimary,
              ),
              _HeroStat(
                label: 'Reaproveitados',
                value: metrics.reusedItems,
                color: colorScheme.onPrimary,
              ),
              _HeroStat(
                label: 'Vencendo hoje',
                value: metrics.expiringToday,
                color: colorScheme.onPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme colorScheme) {
    final actions = [
      _QuickActionData(
        title: 'Adicionar',
        subtitle: 'Novo produto',
        icon: Icons.add_box_rounded,
        onTap: _navigateToAddProduct,
        color: colorScheme.primary,
      ),
      _QuickActionData(
        title: 'Missões',
        subtitle: 'Desafios',
        icon: Icons.emoji_events_outlined,
        onTap: () => Navigator.of(context).pushNamed('/missions'),
        color: Colors.purple,
      ),
      _QuickActionData(
        title: 'Calendário',
        subtitle: 'Validades',
        icon: Icons.calendar_month_rounded,
        onTap: () => _onItemTapped(1),
        color: Colors.orange,
      ),
      _QuickActionData(
        title: 'Impacto',
        subtitle: 'Resultados',
        icon: Icons.auto_graph_rounded,
        onTap: () => _onItemTapped(2),
        color: Colors.green,
      ),
    ];

    return Column(
      children: [
        Row(
          children: actions
              .take(2)
              .map((action) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StyleTokens.spacingS,
                      ),
                      child: _QuickActionCard(data: action),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: StyleTokens.spacingS),
        Row(
          children: actions
              .skip(2)
              .map((action) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StyleTokens.spacingS,
                      ),
                      child: _QuickActionCard(data: action),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final userName = _resolveUserName(authState);

    return Scaffold(
      appBar: _selectedIndex == 0 
          ? AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                'Olá, $userName!',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevation: 0,
              actions: [
                IconButton(
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                  onPressed: () {
                    logger.logInfo('Botão de notificações pressionado');
                  },
                ),
              ],
            )
          : null,
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Theme.of(context).brightness == Brightness.dark
              ? null
              : Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Calendário',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Impacto',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              label: 'Compras',
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão de Receitas
          FloatingActionButton(
            heroTag: 'recipes_button',
            onPressed: () {
              Navigator.pushNamed(context, '/recipes');
            },
            backgroundColor: Colors.green,
            mini: true,
            child: const Icon(Icons.restaurant_menu, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Botão de Adicionar Produto
          FloatingActionButton(
            heroTag: 'add_product_button',
            onPressed: _navigateToAddProduct,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _HomeMetrics {
  final int totalItems;
  final int reusedItems;
  final int expiringToday;
  final int criticalItems;

  const _HomeMetrics({
    required this.totalItems,
    required this.reusedItems,
    required this.expiringToday,
    required this.criticalItems,
  });

  factory _HomeMetrics.fromProducts(List<Product> products) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    int active = 0;
    int reused = 0;
    int expiringToday = 0;
    int critical = 0;

    for (final product in products) {
      final expiration = product.expirationDate;
      if (product.isConsumed) {
        reused++;
        continue;
      }

      active++;
      if (expiration == null) continue;

      if (!expiration.isBefore(todayStart) && expiration.isBefore(todayEnd)) {
        expiringToday++;
      }

      final daysDiff = expiration.difference(todayStart).inDays;
      if (daysDiff >= 0 && daysDiff <= 3) {
        critical++;
      }
    }

    return _HomeMetrics(
      totalItems: active,
      reusedItems: reused,
      expiringToday: expiringToday,
      criticalItems: critical,
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.color,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: data.color.withValues(alpha: 0.15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withValues(alpha: 0.2),
              ),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(height: 12),
            Text(
              data.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
