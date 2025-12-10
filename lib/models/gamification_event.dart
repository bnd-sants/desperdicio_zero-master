import 'package:equatable/equatable.dart';

class GamificationEvent extends Equatable {
  const GamificationEvent({
    required this.id,
    required this.eventType,
    required this.title,
    this.description,
    required this.xpChange,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String eventType;
  final String title;
  final String? description;
  final int xpChange;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  factory GamificationEvent.fromMap(Map<String, dynamic> map) {
    return GamificationEvent(
      id: map['id'] as String,
      eventType: map['event_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      xpChange: (map['xp_change'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, eventType, title, description, xpChange, metadata, createdAt];
}
