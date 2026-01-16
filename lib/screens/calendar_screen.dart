import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../../models/meal_model.dart';
import '../../models/product_model.dart';
import '../../core/providers/index.dart';
import 'add_product/add_product_screen.dart';

DateTime _normalizeDay(DateTime day) => DateTime.utc(day.year, day.month, day.day);

final calendarEventsProvider = FutureProvider<List<Meal>>((ref) async {
  final productState = ref.watch(productsProvider);
  final products = productState.products;

  return products.map((product) {
    return Meal(
      id: product.id,
      name: product.name,
      category: product.type ?? 'Sem categoria',
      area: 'Local',
      instructions: 'Sem instruções disponíveis',
      thumbnailUrl: '',
      tags: [],
      youtubeUrl: '',
      ingredients: [
        Ingredient(
          name: product.name,
          measure: '${product.quantity} ${product.unit}',
        ),
      ],
      dateModified: product.expirationDate?.toIso8601String(),
    );
  }).toList();
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _MonthlySummary {
  final int totalItems;
  final int consumed;
  final int expiringSoon;
  final int expired;

  const _MonthlySummary({
    required this.totalItems,
    required this.consumed,
    required this.expiringSoon,
    required this.expired,
  });
}

_MonthlySummary _calculateMonthlySummary(List<Product> products, DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1);
  int total = 0;
  int consumed = 0;
  int expiringSoon = 0;
  int expired = 0;

  final now = DateTime.now();

  for (final product in products) {
    final expiration = product.expirationDate;
    if (expiration == null) continue;
    if (expiration.isBefore(start) || !expiration.isBefore(end)) continue;

    total++;
    if (product.isConsumed) {
      consumed++;
      continue;
    }

    if (expiration.isBefore(now)) {
      expired++;
    } else if (expiration.difference(now).inDays <= 3) {
      expiringSoon++;
    }
  }

  return _MonthlySummary(
    totalItems: total,
    consumed: consumed,
    expiringSoon: expiringSoon,
    expired: expired,
  );
}

Widget _buildMonthlySummaryCard(
  BuildContext context,
  _MonthlySummary summary, {
  required DateTime month,
}) {
  final theme = Theme.of(context);
  final monthLabel = DateFormat('MMMM yyyy', 'pt_BR').format(month);

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de $monthLabel',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryStat(
                label: 'Itens no mês',
                value: summary.totalItems,
                color: theme.colorScheme.primary,
              ),
              _SummaryStat(
                label: 'Reaproveitados',
                value: summary.consumed,
                color: Colors.green,
              ),
              _SummaryStat(
                label: 'Vencendo em 3d',
                value: summary.expiringSoon,
                color: Colors.orange,
              ),
              _SummaryStat(
                label: 'Perdidos',
                value: summary.expired,
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

Widget _buildDayCell({
  required BuildContext context,
  required DateTime day,
  required ColorScheme colorScheme,
  required bool isSelected,
  required bool isToday,
  required int eventCount,
  required int maxEvents,
}) {
  final theme = Theme.of(context);
  final baseColor = _heatmapColorForCount(eventCount, maxEvents, colorScheme);
  final backgroundColor = isSelected
      ? colorScheme.primary
      : isToday
          ? colorScheme.primary.withValues(alpha: 0.2)
          : baseColor;
  final textColor = isSelected
      ? colorScheme.onPrimary
      : isToday
          ? colorScheme.primary
          : theme.textTheme.bodyMedium?.color;

  return Container(
    margin: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isSelected
            ? colorScheme.primary
            : baseColor?.withValues(alpha: 0.4) ?? Colors.transparent,
        width: isSelected ? 1.5 : 1,
      ),
    ),
    child: Center(
      child: Text(
        '${day.day}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    ),
  );
}

Color? _heatmapColorForCount(
  int eventCount,
  int maxEvents,
  ColorScheme colorScheme,
) {
  if (eventCount == 0 || maxEvents == 0) return colorScheme.surfaceContainerHighest;
  final ratio = eventCount / maxEvents;
  return Color.lerp(
    colorScheme.primary.withValues(alpha: 0.1),
    colorScheme.error.withValues(alpha: 0.4),
    ratio.clamp(0, 1),
  );
}

int _maxEventsForMonth(
  Map<DateTime, List<Meal>> eventsByDay,
  DateTime month,
) {
  int maxCount = 0;
  for (final entry in eventsByDay.entries) {
    final day = entry.key;
    if (day.year == month.year && day.month == month.month) {
      if (entry.value.length > maxCount) {
        maxCount = entry.value.length;
      }
    }
  }
  return maxCount;
}
class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Set<DateTime> _selectedDays = {};
  Map<DateTime, List<Meal>> _eventsByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadInitialData();
    initializeDateFormatting('pt_BR', null);
  }

  Future<void> _loadInitialData() async {
    try {
      final result = await ref.refresh(calendarEventsProvider.future);
      debugPrint('Calendário atualizado: ${result.length} itens carregados');
    } catch (e) {
      debugPrint('Erro ao atualizar calendário: $e');
    }
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventsAsync = ref.watch(calendarEventsProvider);
    final productsState = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Validade',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        automaticallyImplyLeading: false, // Remove o botão de voltar
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
            onPressed: _loadInitialData,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Container(
            color: colorScheme.surface,
            child: eventsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ocorreu um erro ao carregar o calendário',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erro: $error',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(calendarEventsProvider.future),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              data: (events) {
                // Agrupar eventos por dia
                _eventsByDay = {};
                for (var event in events) {
                  if (event.dateModified != null) {
                    try {
                      final eventDate = DateTime.parse(event.dateModified!);
                      final day = _normalizeDay(eventDate);
                      if (_eventsByDay[day] == null) {
                        _eventsByDay[day] = [];
                      }
                      _eventsByDay[day]!.add(event);
                    } catch (e) {
                      debugPrint('Erro ao processar data: $e');
                    }
                  }
                }

                final monthlySummary = _calculateMonthlySummary(
                  productsState.products,
                  DateTime(_focusedDay.year, _focusedDay.month),
                );

                final maxEventsForMonth =
                    _maxEventsForMonth(_eventsByDay, _focusedDay);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildMonthlySummaryCard(
                        context,
                        monthlySummary,
                        month: _focusedDay,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TableCalendar<Meal>(
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                        focusedDay: _focusedDay,
                        locale: 'pt_BR',
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                        },
                        eventLoader: (day) =>
                            _eventsByDay[_normalizeDay(day)] ?? [],
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) =>
                              _buildDayCell(
                            context: context,
                            day: day,
                            colorScheme: colorScheme,
                            isSelected: _isSameDay(day, _selectedDay),
                            isToday: _isSameDay(day, DateTime.now()),
                            eventCount:
                                (_eventsByDay[_normalizeDay(day)] ?? []).length,
                            maxEvents: maxEventsForMonth,
                          ),
                          todayBuilder: (context, day, focusedDay) =>
                              _buildDayCell(
                            context: context,
                            day: day,
                            colorScheme: colorScheme,
                            isSelected: false,
                            isToday: true,
                            eventCount:
                                (_eventsByDay[_normalizeDay(day)] ?? []).length,
                            maxEvents: maxEventsForMonth,
                          ),
                          selectedBuilder: (context, day, focusedDay) =>
                              _buildDayCell(
                            context: context,
                            day: day,
                            colorScheme: colorScheme,
                            isSelected: true,
                            isToday: _isSameDay(day, DateTime.now()),
                            eventCount:
                                (_eventsByDay[_normalizeDay(day)] ?? []).length,
                            maxEvents: maxEventsForMonth,
                          ),
                        ),
                        selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _selectedDays.add(selectedDay);
                          });
                        },
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mês',
                          CalendarFormat.twoWeeks: '2 Semanas',
                          CalendarFormat.week: 'Semana',
                        },
                        // Header style is defined later in the widget
                        calendarStyle: CalendarStyle(
                          defaultDecoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          weekendDecoration: BoxDecoration(
                            shape: BoxShape.circle, 
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 128),
                          ),
                          todayDecoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          selectedTextStyle: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          weekendTextStyle: TextStyle(
                            color: colorScheme.error,
                          ),
                          markerDecoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          markerSize: 6,
                          markerMargin:
                              const EdgeInsets.symmetric(horizontal: 1.5),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left_rounded,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right_rounded,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          weekendStyle: TextStyle(
                            color: colorScheme.error.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Text(
                            'Eventos do dia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _selectedDay != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedDay!)
                                : 'Selecione uma data',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildEventList(
                        _selectedDay != null
                            ? _eventsByDay[_normalizeDay(_selectedDay!)] ?? []
                            : [],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(
                onProductAdded: (_) =>
                    ref.refresh(calendarEventsProvider.future),
              ),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList(List<Meal> events) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento para esta data',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final event = events[index];
        final eventDate = event.dateModified != null
            ? DateTime.parse(event.dateModified!)
            : null;
        final daysUntilExpiration =
            eventDate?.difference(DateTime.now()).inDays ?? 0;
        final isExpired = daysUntilExpiration < 0;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Navegar para os detalhes do produto ou refeição
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.red.withValues(alpha: 0.1)
                            : colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fastfood_rounded,
                        color: isExpired ? Colors.red : colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.category,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.red.withValues(alpha: 0.1)
                            : colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isExpired ? 'Vencido' : '${daysUntilExpiration + 1}d',
                        style: TextStyle(
                          color: isExpired ? Colors.red : colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
