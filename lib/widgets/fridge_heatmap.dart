import 'package:flutter/material.dart';
import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:intl/intl.dart';

class FridgeHeatmapSection extends StatelessWidget {
  final List<Product> products;

  const FridgeHeatmapSection({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final layout = _HeatmapLayout.fromProducts(products);
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.kitchen_outlined, color: colorScheme.primary),
              const SizedBox(width: StyleTokens.spacingS),
              Text(
                'Mapa da geladeira',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '${layout.criticalCount} críticos · ${layout.warningCount} atenção',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: StyleTokens.spacingM),
          Column(
            children: List.generate(layout.shelves.length, (index) {
              final shelf = layout.shelves[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == layout.shelves.length - 1
                      ? 0
                      : StyleTokens.spacingS,
                ),
                child: _FridgeShelfRow(
                  label: 'Prateleira ${index + 1}',
                  slots: shelf,
                ),
              );
            }),
          ),
          const SizedBox(height: StyleTokens.spacingM),
          const _HeatmapLegend(),
          const SizedBox(height: StyleTokens.spacingS),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showDetailSheet(context, layout),
              icon: const Icon(Icons.fullscreen),
              label: const Text('Ver detalhes'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context, _HeatmapLayout layout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(StyleTokens.spacingL),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      Icon(Icons.kitchen, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: StyleTokens.spacingS),
                      Text(
                        'Mapa detalhado',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: StyleTokens.spacingL),
                  Column(
                    children: List.generate(layout.shelves.length, (index) {
                      final shelf = layout.shelves[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: StyleTokens.spacingM),
                        child: _FridgeShelfRow(
                          label: 'Prateleira ${index + 1}',
                          slots: shelf,
                          dense: false,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: StyleTokens.spacingL),
                  Text(
                    'Itens críticos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: StyleTokens.spacingS),
                  ...layout.criticalProducts.map((product) => _HeatmapProductTile(product: product)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FridgeShelfRow extends StatelessWidget {
  final String label;
  final List<_HeatmapSlot> slots;
  final bool dense;

  const _FridgeShelfRow({
    required this.label,
    required this.slots,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!dense)
          Padding(
            padding: const EdgeInsets.only(bottom: StyleTokens.spacingS),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Row(
          children: slots
              .map(
                (slot) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: slot == slots.last ? 0 : StyleTokens.spacingS,
                    ),
                    child: _HeatmapSlotTile(slot: slot, colorScheme: colorScheme, compact: dense),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _HeatmapSlotTile extends StatelessWidget {
  final _HeatmapSlot slot;
  final ColorScheme colorScheme;
  final bool compact;

  const _HeatmapSlotTile({
    required this.slot,
    required this.colorScheme,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color border;
    final IconData icon;

    switch (slot.level) {
      case HeatLevel.critical:
        background = colorScheme.error.withValues(alpha: 0.15);
        border = colorScheme.error;
        icon = Icons.warning_amber_rounded;
        break;
      case HeatLevel.warning:
        background = colorScheme.tertiary.withValues(alpha: 0.15);
        border = colorScheme.tertiary;
        icon = Icons.access_time;
        break;
      case HeatLevel.safe:
        background = colorScheme.primary.withValues(alpha: 0.12);
        border = colorScheme.primary;
        icon = Icons.check_circle_outline;
        break;
      case HeatLevel.empty:
        background = colorScheme.surface;
        border = colorScheme.outlineVariant;
        icon = Icons.add;
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(StyleTokens.radiusM),
      onTap: slot.product == null
          ? null
          : () => _showSlotInfo(context, slot.product!, slot.daysUntilExpiry ?? 999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(
          vertical: compact ? StyleTokens.spacingM : StyleTokens.spacingL,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(StyleTokens.radiusM),
          border: Border.all(color: border.withValues(alpha: 0.6), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 18 : 22, color: border),
            if (slot.product != null) ...[
              const SizedBox(height: StyleTokens.spacingXS),
              Text(
                slot.product!.name,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (slot.daysUntilExpiry != null)
                Text(
                  slot.daysUntilExpiry! <= 0
                      ? 'Venceu'
                      : '${slot.daysUntilExpiry} dia${slot.daysUntilExpiry == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: border,
                      ),
                ),
            ] else ...[
              const SizedBox(height: StyleTokens.spacingXS),
              Text(
                'Livre',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSlotInfo(BuildContext context, Product product, int daysUntil) {
    final formatter = DateFormat('dd/MM/yyyy');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(StyleTokens.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fastfood_outlined, color: colorScheme.primary),
                  const SizedBox(width: StyleTokens.spacingS),
                  Expanded(
                    child: Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    daysUntil <= 0
                        ? 'Vencido'
                        : '${daysUntil}d',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: daysUntil <= 1
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: StyleTokens.spacingM),
              if (product.expirationDate != null)
                Text('Validade: ${formatter.format(product.expirationDate!)}'),
              Text('Quantidade: ${product.quantity} ${product.unit}'),
              if (product.brand != null && product.brand!.isNotEmpty)
                Text('Marca: ${product.brand}'),
              const SizedBox(height: StyleTokens.spacingL),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.done),
                      label: const Text('Marcar como consumido'),
                    ),
                  ),
                  const SizedBox(width: StyleTokens.spacingS),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.swap_vert),
                    label: const Text('Mover'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();

  @override
  Widget build(BuildContext context) {
    final items = [
      _LegendEntry('Seguro', HeatLevel.safe),
      _LegendEntry('Atenção', HeatLevel.warning),
      _LegendEntry('Crítico', HeatLevel.critical),
      _LegendEntry('Livre', HeatLevel.empty),
    ];

    return Wrap(
      spacing: StyleTokens.spacingM,
      runSpacing: StyleTokens.spacingS,
      children: items
          .map((entry) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(level: entry.level),
                  const SizedBox(width: StyleTokens.spacingXS),
                  Text(
                    entry.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ))
          .toList(),
    );
  }
}

class _LegendEntry {
  final String label;
  final HeatLevel level;

  const _LegendEntry(this.label, this.level);
}

class _LegendDot extends StatelessWidget {
  final HeatLevel level;

  const _LegendDot({required this.level});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    switch (level) {
      case HeatLevel.safe:
        color = colorScheme.primary;
        break;
      case HeatLevel.warning:
        color = colorScheme.tertiary;
        break;
      case HeatLevel.critical:
        color = colorScheme.error;
        break;
      case HeatLevel.empty:
        color = colorScheme.outlineVariant;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: level == HeatLevel.empty ? Colors.transparent : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class _HeatmapLayout {
  final List<List<_HeatmapSlot>> shelves;
  final List<Product> criticalProducts;
  final int criticalCount;
  final int warningCount;

  _HeatmapLayout({
    required this.shelves,
    required this.criticalProducts,
    required this.criticalCount,
    required this.warningCount,
  });

  factory _HeatmapLayout.fromProducts(List<Product> products) {
    const shelfCount = 3;
    const slotsPerShelf = 4;
    final totalSlots = shelfCount * slotsPerShelf;

    final sorted = [...products]
      ..sort((a, b) => _daysUntil(a).compareTo(_daysUntil(b)));

    final slots = List<_HeatmapSlot>.generate(totalSlots, (index) {
      if (index >= sorted.length) {
        return _HeatmapSlot.empty();
      }
      final product = sorted[index];
      final days = _daysUntil(product);
      return _HeatmapSlot(product: product, daysUntilExpiry: days);
    });

    final shelves = List.generate(
      shelfCount,
      (shelfIndex) => slots.skip(shelfIndex * slotsPerShelf).take(slotsPerShelf).toList(),
    );

    final criticalProducts = sorted.where((p) => _levelFromProduct(p) == HeatLevel.critical).toList();
    final criticalCount = criticalProducts.length;
    final warningCount = sorted.where((p) => _levelFromProduct(p) == HeatLevel.warning).length;

    return _HeatmapLayout(
      shelves: shelves,
      criticalProducts: criticalProducts,
      criticalCount: criticalCount,
      warningCount: warningCount,
    );
  }
}

class _HeatmapSlot {
  final Product? product;
  final int? daysUntilExpiry;
  final HeatLevel level;

  _HeatmapSlot({required this.product, required this.daysUntilExpiry})
      : level = product == null ? HeatLevel.empty : _levelFromDays(daysUntilExpiry);

  _HeatmapSlot.empty()
      : product = null,
        daysUntilExpiry = null,
        level = HeatLevel.empty;
}

enum HeatLevel { safe, warning, critical, empty }

int _daysUntil(Product product) {
  if (product.expirationDate == null) return 99;
  return product.expirationDate!
      .difference(DateTime.now())
      .inDays;
}

HeatLevel _levelFromProduct(Product product) => _levelFromDays(_daysUntil(product));

HeatLevel _levelFromDays(int? days) {
  if (days == null) return HeatLevel.empty;
  if (days <= 1) return HeatLevel.critical;
  if (days <= 4) return HeatLevel.warning;
  return HeatLevel.safe;
}

class _HeatmapProductTile extends StatelessWidget {
  final Product product;

  const _HeatmapProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final days = _daysUntil(product);
    return Padding(
      padding: const EdgeInsets.only(bottom: StyleTokens.spacingS),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleTokens.radiusM),
          side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
        ),
        leading: Icon(Icons.warning_amber_rounded, color: colorScheme.error),
        title: Text(product.name),
        subtitle: product.expirationDate != null
            ? Text('Validade: ${DateFormat('dd/MM').format(product.expirationDate!)}')
            : const Text('Sem validade registrada'),
        trailing: Text(
          days <= 0 ? 'Vencido' : '${days}d',
          style: TextStyle(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
