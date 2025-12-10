import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/providers/index.dart';
import '../../models/meal_model.dart';
import 'add_product/add_product_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de Validade',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
            onPressed: () => ref.refresh(calendarEventsProvider.future),
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
                      final eventDate = DateTime.parse(event.dateModified!).toUtc();
                      final day = DateTime.utc(
                          eventDate.year, eventDate.month, eventDate.day);
                      if (_eventsByDay[day] == null) {
                        _eventsByDay[day] = [];
                      }
                      _eventsByDay[day]!.add(event);
                    } catch (e) {
                      debugPrint('Erro ao processar data: $e');
                    }
                  }
                }

                return Column(
                  children: [
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
                        selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            _selectedDays.add(selectedDay);
                          });
                        },
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        eventLoader: (day) => _eventsByDay[day] ?? [],
                        calendarStyle: CalendarStyle(
                          defaultDecoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          weekendDecoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                            ? _eventsByDay[_selectedDay!] ?? []
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
