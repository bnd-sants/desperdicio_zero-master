class MonthlyWastePoint {
  final DateTime month;
  final int consumed;
  final int wasted;

  const MonthlyWastePoint({
    required this.month,
    required this.consumed,
    required this.wasted,
  });
}

class ForecastPoint {
  final DateTime date;
  final double predictedWaste;

  const ForecastPoint({
    required this.date,
    required this.predictedWaste,
  });
}
