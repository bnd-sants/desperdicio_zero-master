import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:desperdicio_zero/core/providers/products/product_provider.dart';
import 'package:desperdicio_zero/core/providers/metrics/metrics_provider.dart';
import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/services/metrics_service.dart';

const double _co2FactorPerKg = 2.5; // kg de CO₂ evitado por kg reaproveitado
const double _waterFactorPerKg = 1600; // litros economizados por kg reaproveitado (FAO média)
const double _defaultUnitWeightKg = 0.25; // peso médio assumido para unidades sem peso informado
const double _averagePricePerKg = 15.0; // estimativa padrão para valor em R$

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

Widget _buildXpProgressChart(
  BuildContext context,
  GamificationSummary summary,
) {
  final theme = Theme.of(context);
  final xpCurrent = summary.xpTotal.clamp(0, summary.xpNextLevel).toDouble();
  final xpRemaining = (summary.xpNextLevel - summary.xpTotal).clamp(0, summary.xpNextLevel).toDouble();
  final total = (xpCurrent + xpRemaining).clamp(1, double.infinity);

  final sections = [
    PieChartSectionData(
      value: xpCurrent,
      color: theme.colorScheme.primary,
      title: '${(xpCurrent / total * 100).round()}%',
      radius: 80,
      titleStyle: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
    PieChartSectionData(
      value: xpRemaining,
      color: theme.colorScheme.surfaceVariant,
      title: xpRemaining == 0 ? '100%' : '${(xpRemaining / total * 100).round()}%',
      radius: 60,
      titleStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  ];

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolução de XP',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Acompanhe o progresso até o próximo nível.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: sections,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildConsumptionChart(
  BuildContext context,
  ProductMetrics metrics,
) {
  final theme = Theme.of(context);
  final consumed = metrics.consumedItems.toDouble();
  final wasted = metrics.expiredItems.toDouble();

  if (consumed == 0 && wasted == 0) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consumo vs. Descarte',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ainda não há dados suficientes. Consuma ou registre descartes para ver o gráfico.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  final barGroups = [
    BarChartGroupData(
      x: 0,
      barRods: [
        BarChartRodData(
          toY: consumed,
          color: Colors.green,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    ),
    BarChartGroupData(
      x: 1,
      barRods: [
        BarChartRodData(
          toY: wasted,
          color: Colors.redAccent,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ],
    ),
  ];

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consumo vs. Descarte',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Compare quantos itens foram consumidos e quantos foram desperdiçados.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, horizontalInterval: 1),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 42),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('Consumidos'),
                            );
                          case 1:
                            return const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('Descartados'),
                            );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                alignment: BarChartAlignment.spaceAround,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSummaryCard(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String value,
  required IconData icon,
  required Color color,
}) {
  final theme = Theme.of(context);
  return SizedBox(
    width: 180,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildSummaryChip(
  BuildContext context, {
  required String label,
  required String value,
  required IconData icon,
}) {
  final theme = Theme.of(context);
  return Chip(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
    label: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
  );
}

List<Product> _getUpcomingProducts(List<Product> products) {
  final now = DateTime.now();
  final limit = now.add(const Duration(days: 3));
  final upcoming = products.where((product) {
    final expiration = product.expirationDate;
    if (expiration == null || product.isConsumed) return false;
    return !expiration.isBefore(now) && !expiration.isAfter(limit);
  }).toList();
  upcoming.sort((a, b) => a.expirationDate!.compareTo(b.expirationDate!));
  return upcoming;
}

Widget _buildInsightsCard(
  BuildContext context, {
  required List<Product> upcomingProducts,
  required double potentialKg,
  required double potentialCo2,
  required double potentialSavings,
}) {
  final theme = Theme.of(context);
  final soonNames = upcomingProducts.take(3).map((p) => p.name).join(', ');
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itens prestes a vencer',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            upcomingProducts.length == 1
                ? 'Há 1 item perto do vencimento. Consuma-o para evitar desperdiçar ${potentialKg.toStringAsFixed(2)} kg.'
                : 'Há ${upcomingProducts.length} itens perto do vencimento. Reaproveitando todos você evita desperdiçar ${potentialKg.toStringAsFixed(2)} kg.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Impacto potencial: ${potentialCo2.toStringAsFixed(2)} kg de CO₂ e ${potentialSavings.toStringAsFixed(2)} em economia.',
            style: theme.textTheme.bodySmall,
          ),
          if (soonNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Sugestão: $soonNames...',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ImpactMetrics {
  final double co2SavedKg;
  final double waterSavedLiters;
  final double wasteReducedKg;
  final double moneySaved;
  final double reusedValue;
  final int reusedItems;

  const _ImpactMetrics({
    required this.co2SavedKg,
    required this.waterSavedLiters,
    required this.wasteReducedKg,
    required this.moneySaved,
    required this.reusedValue,
    required this.reusedItems,
  });

  const _ImpactMetrics.empty()
      : this(
          co2SavedKg: 0,
          waterSavedLiters: 0,
          wasteReducedKg: 0,
          moneySaved: 0,
          reusedValue: 0,
          reusedItems: 0,
        );
}

_ImpactMetrics _calculateImpactMetrics(List<Product> products) {
  double totalKgReused = 0;
  double totalPriceKnown = 0;
  double totalKgWithoutPrice = 0;
  int reusedItems = 0;

  for (final product in products) {
    if (!product.isConsumed) continue;

    final unit = product.unit.toLowerCase();
    final kg = _convertToKg(product.quantity.toDouble(), unit);
    totalKgReused += kg;
    reusedItems++;

    if (product.price != null && product.price! > 0) {
      totalPriceKnown += product.price!;
    } else {
      totalKgWithoutPrice += kg;
    }
  }

  final estimatedFromUnknown = totalKgWithoutPrice * _averagePricePerKg;
  final moneySaved = totalPriceKnown + estimatedFromUnknown;
  final reusedValue = totalKgReused * _averagePricePerKg;

  return _ImpactMetrics(
    co2SavedKg: totalKgReused * _co2FactorPerKg,
    waterSavedLiters: totalKgReused * _waterFactorPerKg,
    wasteReducedKg: totalKgReused,
    moneySaved: moneySaved,
    reusedValue: reusedValue,
    reusedItems: reusedItems,
  );
}

double _convertToKg(double quantity, String unit) {
  switch (unit.trim().toLowerCase()) {
    case 'kg':
      return quantity;
    case 'g':
      return quantity / 1000;
    case 'l':
    case 'lt':
    case 'litro':
    case 'litros':
      return quantity; // densidade aproximada da água/alimentos líquidos
    case 'ml':
      return quantity / 1000;
    default:
      return quantity * _defaultUnitWeightKg;
  }
}

double _getEnvironmentalMetricValue(String key, _ImpactMetrics metrics) {
  switch (key) {
    case 'co2':
      return metrics.co2SavedKg;
    case 'water':
      return metrics.waterSavedLiters;
    case 'waste':
      return metrics.wasteReducedKg;
    default:
      return 0;
  }
}

double _getEconomicMetricValue(String key, _ImpactMetrics metrics) {
  switch (key) {
    case 'savings':
      return metrics.moneySaved;
    case 'reused':
      return metrics.reusedValue;
    default:
      return 0;
  }
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  final Map<String, _MetricData> _environmentalMetricTemplates = {
    'co2': _MetricData(
      title: 'CO₂ evitado',
      subtitle: 'Quantidade de emissões evitadas ao consumir seus produtos',
      unit: 'kg',
      icon: Icons.cloud_done_outlined,
      color: Colors.green,
      value: 0,
    ),
    'water': _MetricData(
      title: 'Água economizada',
      subtitle: 'Estimativa de litros preservados',
      unit: 'L',
      icon: Icons.water_drop_outlined,
      color: Colors.blue,
      value: 0,
    ),
    'waste': _MetricData(
      title: 'Resíduos reduzidos',
      subtitle: 'Peso de alimentos que não viraram lixo',
      unit: 'kg',
      icon: Icons.delete_sweep_outlined,
      color: Colors.orange,
      value: 0,
    ),
  };

  final Map<String, _MetricData> _economicMetricTemplates = {
    'savings': _MetricData(
      title: 'Dinheiro economizado',
      subtitle: 'Total estimado em compras evitadas',
      unit: 'R\$',
      icon: Icons.savings_outlined,
      color: Colors.teal,
      value: 0,
    ),
    'reused': _MetricData(
      title: 'Alimentos reaproveitados',
      subtitle: 'Valor agregado aos itens reaproveitados',
      unit: 'R\$',
      icon: Icons.restart_alt,
      color: Colors.purple,
      value: 0,
    ),
  };

  final Map<String, double> _environmentalOverrides = {};
  final Map<String, double> _economicOverrides = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metricsAsync = ref.watch(metricsProvider);
    final productsState = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impacto Ambiental & Econômico'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(metricsProvider.notifier).refresh(),
            ref.read(productsProvider.notifier).refresh(),
          ]);
        },
        child: metricsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 48),
            children: const [
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildMessageCard(
                context,
                title: 'Não foi possível carregar as métricas',
                message: error.toString(),
                icon: Icons.error_outline,
              ),
            ],
          ),
          data: (snapshot) => _buildDashboardContent(
            context,
            snapshot,
            productsState,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    MetricsSnapshot? snapshot,
    ProductState productsState,
  ) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.decimalPattern('pt_BR');
    final productMetrics = snapshot?.productMetrics;
    final gamificationSummary = snapshot?.gamificationSummary;

    final upcomingProducts = _getUpcomingProducts(productsState.products);
    double potentialKg = 0;
    double potentialSavings = 0;

    for (final product in upcomingProducts) {
      final kg = _convertToKg(product.quantity.toDouble(), product.unit);
      potentialKg += kg;
      potentialSavings += (product.price != null && product.price! > 0)
          ? product.price!
          : kg * _averagePricePerKg;
    }

    final potentialCo2 = potentialKg * _co2FactorPerKg;

    final impactMetrics = productsState.when(
      loading: () => const _ImpactMetrics.empty(),
      error: (_) => const _ImpactMetrics.empty(),
      data: _calculateImpactMetrics,
    );

    final children = <Widget>[];

    if (snapshot == null) {
      children.add(
        _buildMessageCard(
          context,
          title: 'Entre para acessar suas métricas',
          message: 'Faça login para acompanhar impacto, progresso e oportunidades.',
          icon: Icons.lock_outline,
        ),
      );
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: children,
      );
    }

    if (productMetrics != null) {
      children.addAll([
        Text(
          'Resumo da Despensa',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSummaryCard(
              context,
              title: 'Itens ativos',
              subtitle: 'Produtos disponíveis agora',
              value: numberFormat.format(productMetrics.activeItems),
              icon: Icons.inventory_2_outlined,
              color: Colors.teal,
            ),
            _buildSummaryCard(
              context,
              title: 'Consumidos',
              subtitle: 'Total marcado como consumido',
              value: numberFormat.format(productMetrics.consumedItems),
              icon: Icons.restaurant_outlined,
              color: Colors.green,
            ),
            _buildSummaryCard(
              context,
              title: 'A vencer (3 dias)',
              subtitle: 'Olho neles antes que estraguem',
              value: numberFormat.format(productMetrics.expiringSoonItems),
              icon: Icons.warning_amber_outlined,
              color: Colors.orange,
            ),
            _buildSummaryCard(
              context,
              title: 'Quantidade ativa',
              subtitle: 'Estoque disponível (unid./kg)',
              value: numberFormat.format(productMetrics.activeQuantity),
              icon: Icons.scale_outlined,
              color: Colors.indigo,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildConsumptionChart(context, productMetrics),
        const SizedBox(height: 24),
      ]);
    }

    if (gamificationSummary != null) {
      final xpProgress = gamificationSummary.xpNextLevel == 0
          ? 0.0
          : (gamificationSummary.xpTotal / gamificationSummary.xpNextLevel)
              .clamp(0, 1)
              .toDouble();
      final xpFormat = NumberFormat.compactCurrency(
        decimalDigits: 0,
        symbol: '',
        locale: 'pt_BR',
      );
      final lastReset = gamificationSummary.lastReset != null
          ? DateFormat('dd/MM/yyyy').format(gamificationSummary.lastReset!.toLocal())
          : '—';

      children.addAll([
        Text(
          'Progresso de Gamificação',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nível ${gamificationSummary.currentLevel}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${xpFormat.format(gamificationSummary.xpTotal)} XP de ${xpFormat.format(gamificationSummary.xpNextLevel)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: xpProgress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildSummaryChip(
                      context,
                      label: 'Missões concluídas',
                      value: numberFormat.format(gamificationSummary.completedMissions),
                      icon: Icons.check_circle_outline,
                    ),
                    _buildSummaryChip(
                      context,
                      label: 'Missões ativas',
                      value: numberFormat.format(gamificationSummary.activeMissions),
                      icon: Icons.flag_outlined,
                    ),
                    _buildSummaryChip(
                      context,
                      label: 'Badges desbloqueadas',
                      value: numberFormat.format(gamificationSummary.unlockedBadges),
                      icon: Icons.loyalty_outlined,
                    ),
                    _buildSummaryChip(
                      context,
                      label: 'Último reset',
                      value: lastReset,
                      icon: Icons.history_toggle_off,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildXpProgressChart(context, gamificationSummary),
        const SizedBox(height: 24),
      ]);
    }

    if (productsState.error != null) {
      children.add(
        _buildMessageCard(
          context,
          title: 'Produtos indisponíveis',
          message: productsState.error!,
          icon: Icons.error_outline,
        ),
      );
      children.add(const SizedBox(height: 16));
    }

    final hasImpactData = impactMetrics.reusedItems > 0;

    if (!hasImpactData) {
      children.add(
        _buildMessageCard(
          context,
          title: 'Sem dados reaproveitados ainda',
          message:
              'Consuma ou marque produtos como reaproveitados para vermos o impacto gerado.',
          icon: Icons.info_outline,
        ),
      );
      children.add(const SizedBox(height: 24));
    }

    children.addAll([
      _buildSectionHeader(
        context,
        title: 'Indicadores Ambientais',
        description:
            'Calculados automaticamente a partir dos produtos consumidos/reaproveitados. Você ainda pode ajustar manualmente caso use outra metodologia.',
      ),
      const SizedBox(height: 12),
      ..._environmentalMetricTemplates.entries.map((entry) {
        final value = _environmentalOverrides[entry.key] ??
            _getEnvironmentalMetricValue(entry.key, impactMetrics);
        return _MetricCard(
          data: entry.value.copyWith(value: value),
          onEdit: () => _showEditDialog(
            entry.key,
            isEnvironmental: true,
            currentValue: value,
          ),
        );
      }),
      const SizedBox(height: 24),
      _buildSectionHeader(
        context,
        title: 'Indicadores Econômicos',
        description:
            'Estimados com base nos preços informados ou em valores médios por kg.',
      ),
      const SizedBox(height: 12),
      ..._economicMetricTemplates.entries.map((entry) {
        final value = _economicOverrides[entry.key] ??
            _getEconomicMetricValue(entry.key, impactMetrics);
        return _MetricCard(
          data: entry.value.copyWith(value: value),
          onEdit: () => _showEditDialog(
            entry.key,
            isEnvironmental: false,
            currentValue: value,
          ),
        );
      }),
    ]);

    if (upcomingProducts.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 24),
        _buildInsightsCard(
          context,
          upcomingProducts: upcomingProducts,
          potentialKg: potentialKg,
          potentialCo2: potentialCo2,
          potentialSavings: potentialSavings,
        ),
      ]);
    }

    children.addAll([
      const SizedBox(height: 24),
      _buildTipsCard(
        context,
        currentCo2Value: _environmentalOverrides['co2'] ?? impactMetrics.co2SavedKg,
      ),
      const SizedBox(height: 32),
    ]);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }

  Widget _buildTipsCard(BuildContext context, {required double currentCo2Value}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como calcular o CO₂ economizado?',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Exemplo: para cada 1 kg de alimento reaproveitado você evita ~2,5 kg de CO₂ (FAO, 2023). Multiplique o peso total reaproveitado pelo fator utilizado no seu processo.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showEditDialog(
                'co2',
                isEnvironmental: true,
                currentValue: currentCo2Value,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Atualizar valores manualmente'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    String key, {
    required bool isEnvironmental,
    required double currentValue,
  }) async {
    final templates =
        isEnvironmental ? _environmentalMetricTemplates : _economicMetricTemplates;
    final overrides =
        isEnvironmental ? _environmentalOverrides : _economicOverrides;
    final metric = templates[key]!;
    final controller = TextEditingController(
      text: (overrides[key] ?? currentValue).toStringAsFixed(2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Atualizar ${metric.title}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Valor (${metric.unit})',
            helperText: 'Insira um valor personalizado ou mantenha o cálculo automático',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(double.nan),
            child: const Text('Usar automático'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.replaceAll(',', '.'));
              if (parsed != null) {
                Navigator.of(context).pop(parsed);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (result.isNaN) {
          overrides.remove(key);
        } else {
          overrides[key] = result;
        }
      });
    }
  }
}

Widget _buildMessageCard(
  BuildContext context, {
  required String title,
  required String message,
  required IconData icon,
}) {
  final theme = Theme.of(context);
  return Card(
    margin: const EdgeInsets.only(bottom: 24),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data, required this.onEdit});

  final _MetricData data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: data.color.withValues(alpha: 0.15),
          child: Icon(data.icon, color: data.color),
        ),
        title: Text(
          data.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          data.subtitle,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${data.unit} ${data.value.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: data.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onEdit,
              child: const Text('Editar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.icon,
    required this.color,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String unit;
  final IconData icon;
  final Color color;
  final double value;

  _MetricData copyWith({double? value}) {
    return _MetricData(
      title: title,
      subtitle: subtitle,
      unit: unit,
      icon: icon,
      color: color,
      value: value ?? this.value,
    );
  }
}
