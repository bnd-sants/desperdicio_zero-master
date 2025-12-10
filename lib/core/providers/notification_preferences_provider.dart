import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  final int diasAntes;
  final TimeOfDay horario;
  final List<String> categoriasSilenciadas;
  final bool notificacaoMotivacional;
  final bool receberEmails;
  final bool receberPush;

  const NotificationPreferences({
    this.diasAntes = 2,
    this.horario = const TimeOfDay(hour: 8, minute: 0),
    this.categoriasSilenciadas = const [],
    this.notificacaoMotivacional = true,
    this.receberEmails = true,
    this.receberPush = true,
  });

  NotificationPreferences copyWith({
    int? diasAntes,
    TimeOfDay? horario,
    List<String>? categoriasSilenciadas,
    bool? notificacaoMotivacional,
    bool? receberEmails,
    bool? receberPush,
  }) => NotificationPreferences(
        diasAntes: diasAntes ?? this.diasAntes,
        horario: horario ?? this.horario,
        categoriasSilenciadas: categoriasSilenciadas ?? this.categoriasSilenciadas,
        notificacaoMotivacional: notificacaoMotivacional ?? this.notificacaoMotivacional,
        receberEmails: receberEmails ?? this.receberEmails,
        receberPush: receberPush ?? this.receberPush,
      );

  Map<String, dynamic> toJson() => {
    'diasAntes': diasAntes,
    'horario': '${horario.hour}:${horario.minute}',
    'categoriasSilenciadas': categoriasSilenciadas,
    'notificacaoMotivacional': notificacaoMotivacional,
    'receberEmails': receberEmails,
    'receberPush': receberPush,
  };

  static NotificationPreferences fromJson(Map<String, dynamic> json) {
    final horarioSplit = (json['horario'] as String?)?.split(':') ?? ['8', '0'];
    return NotificationPreferences(
      diasAntes: json['diasAntes'] as int? ?? 2,
      horario: TimeOfDay(
        hour: int.tryParse(horarioSplit[0]) ?? 8,
        minute: int.tryParse(horarioSplit[1]) ?? 0,
      ),
      categoriasSilenciadas: List<String>.from(json['categoriasSilenciadas'] ?? []),
      notificacaoMotivacional: json['notificacaoMotivacional'] as bool? ?? true,
      receberEmails: json['receberEmails'] as bool? ?? true,
      receberPush: json['receberPush'] as bool? ?? true,
    );
  }
}

class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  static const _prefsKey = 'notification_preferences';

  NotificationPreferencesNotifier() : super(const NotificationPreferences()) {
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString != null) {
      try {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        state = NotificationPreferences.fromJson(decoded);
      } catch (_) {}
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  void setDiasAntes(int value) {
    state = state.copyWith(diasAntes: value);
    save();
  }
  void setHorario(TimeOfDay value) {
    state = state.copyWith(horario: value);
    save();
  }
  void toggleCategoria(String categoria) {
    final atual = [...state.categoriasSilenciadas];
    if (atual.contains(categoria)) {
      atual.remove(categoria);
    } else {
      atual.add(categoria);
    }
    state = state.copyWith(categoriasSilenciadas: atual);
    save();
  }
  void setMotivacional(bool value) {
    state = state.copyWith(notificacaoMotivacional: value);
    save();
  }
  void setReceberEmails(bool value) {
    state = state.copyWith(receberEmails: value);
    save();
  }
  void setReceberPush(bool value) {
    state = state.copyWith(receberPush: value);
    save();
  }
  void reset() {
    state = const NotificationPreferences();
    save();
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
        (ref) => NotificationPreferencesNotifier());
