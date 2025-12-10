// lib/core/providers/notifications_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:desperdicio_zero/models/notification_model.dart';
import 'package:desperdicio_zero/services/notification_service.dart' as service;
import 'package:desperdicio_zero/models/product_model.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  static const String _storageKey = 'notifications';
  final service.NotificationService _notificationService = service.NotificationService.instance;

  NotificationsNotifier() : super([]) {
    loadNotifications();
  }

  // Carrega notificações do armazenamento local
  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_storageKey) ?? [];
      
      state = notificationsJson
          .map((json) => AppNotification.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      debugPrint('Erro ao carregar notificações: $e');
    }
  }

  // Salva notificações no armazenamento local
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = state
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, notificationsJson);
    } catch (e) {
      debugPrint('Erro ao salvar notificações: $e');
    }
  }

  // Adiciona uma nova notificação
  Future<void> addNotification(AppNotification notification) async {
    state = [...state, notification];
    await _saveNotifications();
  }

  // Remove notificações selecionadas
  Future<void> removeSelectedNotifications(List<String> notificationIds) async {
    // Primeiro, cancela as notificações no sistema
    for (final id in notificationIds) {
      await _notificationService.cancelNotification(id.hashCode);
    }
    
    // Depois remove da lista
    state = state.where((n) => !notificationIds.contains(n.id)).toList();
    await _saveNotifications();
  }

  // Remove todas as notificações
  Future<void> clearAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    state = [];
    await _saveNotifications();
  }

  // Agenda notificações para produtos próximos ao vencimento
  Future<void> scheduleProductNotifications(List<Product> products, WidgetRef ref) async {
    final now = DateTime.now();
    
    for (final product in products) {
      try {
        if (product.expirationDate != null && product.name.isNotEmpty && product.id.isNotEmpty) {
          final difference = product.expirationDate!.difference(now).inDays;

          if (difference >= 0 && difference <= 3) {
            await service.NotificationService.instance.scheduleStandardProductNotifications(
              ref: ref,
              product: product,
            );

            // Adiciona à lista de notificações
            await addNotification(
              AppNotification(
                id: 'product_${product.id}',
                title: 'Alerta de Validade',
                body: '${product.name} vence em ${difference + 1} dia(s)',
                type: NotificationType.productExpiring,
                payload: {'productId': product.id},
                createdAt: DateTime.now(),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Erro ao agendar notificação para o produto: $e');
      }
    }
  }

  // Cancela notificações de um produto específico
  Future<void> cancelProductNotifications(String productId) async {
    await _notificationService.cancelProductNotifications(productId);
    state = state.where((n) => n.payload?['productId'] != productId).toList();
    await _saveNotifications();
  }

  // Atualiza o status de seleção de uma notificação
  void toggleNotificationSelection(String notificationId) {
    state = state.map((n) {
      if (n.id == notificationId) {
        return AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          createdAt: n.createdAt,
          payload: n.payload,
          isSelected: !n.isSelected,
        );
      }
      return n;
    }).toList();
  }

  // Seleciona/desmarca todas as notificações
  Future<void> toggleSelectAll() async {
    final allSelected = state.every((n) => n.isSelected);
    state = state.map((n) {
      return AppNotification(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        createdAt: n.createdAt,
        payload: n.payload,
        isSelected: !allSelected,
      );
    }).toList();
    await _saveNotifications();
  }

  // Obtém notificações selecionadas
  List<AppNotification> get selectedNotifications =>
      state.where((n) => n.isSelected).toList();

  // Obtém IDs das notificações selecionadas
  List<String> get selectedNotificationIds =>
      state.where((n) => n.isSelected).map((n) => n.id).toList();
}