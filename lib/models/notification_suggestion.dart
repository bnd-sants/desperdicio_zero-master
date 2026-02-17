class NotificationSuggestion {
  final String key;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final Map<String, dynamic> payload;

  const NotificationSuggestion({
    required this.key,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.payload,
  });
}
