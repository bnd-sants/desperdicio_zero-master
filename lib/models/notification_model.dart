// lib/models/notification_model.dart


enum NotificationType {
  productExpiring,
  productExpired,
  shoppingList,
  tip,
  other
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;
  bool isSelected;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.payload,
    this.isSelected = false,
  });

  // Métodos toJson/fromJson para persistência
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        'isSelected': isSelected,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values[json['type'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      payload: json['payload'] as Map<String, dynamic>?,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }
}