// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/notifications_provider.dart';
import 'package:desperdicio_zero/models/notification_model.dart' as model;
import 'package:desperdicio_zero/services/product_service.dart';
import 'package:desperdicio_zero/models/product_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isSelecting = false;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(context, notifications),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(notifications, theme),
      floatingActionButton: _isSelecting
          ? FloatingActionButton.extended(
              onPressed: _clearSelected,
              icon: const Icon(Icons.delete_outline),
              label: Text(
                ref
                        .read(notificationsProvider.notifier)
                        .selectedNotificationIds
                        .isEmpty
                    ? 'Limpar todas'
                    : 'Limpar selecionadas',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF25D366), // Verde WhatsApp
            )
          : null,
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    List<model.AppNotification> notifications,
  ) {
    return AppBar(
      title: _isSelecting
          ? Text(
              '${ref.read(notificationsProvider.notifier).selectedNotificationIds.length} selecionadas',
            )
          : const Text('Notificações'),
      backgroundColor: _isSelecting
          ? Colors.grey[200]
          : const Color(0xFF25D366),
      foregroundColor: _isSelecting ? Colors.black87 : Colors.white,
      elevation: _isSelecting ? 0 : null,
      leading: _isSelecting
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelecting = false;
                ref.read(notificationsProvider.notifier).toggleSelectAll();
              }),
            )
          : null,
      actions: [
        if (notifications.isNotEmpty && !_isSelecting)
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () => setState(() {
              _isSelecting = true;
              ref.read(notificationsProvider.notifier).toggleSelectAll();
            }),
            tooltip: 'Selecionar notificações',
          ),
        if (_isSelecting)
          TextButton(
            onPressed: _selectAll,
            child: Text(
              ref
                          .read(notificationsProvider.notifier)
                          .selectedNotificationIds
                          .length ==
                      ref.read(notificationsProvider).length
                  ? 'Desmarcar todas'
                  : 'Selecionar todas',
              style: const TextStyle(
                color: Color(0xFF25D366),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma notificação',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Novas notificações aparecerão aqui',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    List<model.AppNotification> notifications,
    ThemeData theme,
  ) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification, theme);
      },
    );
  }

  Widget _buildNotificationItem(
    model.AppNotification notification,
    ThemeData theme,
  ) {
    final isSelected = notification.isSelected;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Colors.grey[100] : null,
      child: ListTile(
        leading: _buildLeadingIcon(notification),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(notification.body),
        trailing: _isSelecting
            ? Checkbox(
                value: isSelected,
                onChanged: (value) =>
                    _toggleNotificationSelection(notification.id),
                activeColor: const Color(0xFF25D366),
              )
            : Text(
                _formatDate(notification.createdAt),
                style: theme.textTheme.bodySmall,
              ),
        onTap: _isSelecting
            ? () => _toggleNotificationSelection(notification.id)
            : () => _handleNotificationTap(notification),
        onLongPress: () {
          setState(() {
            _isSelecting = true;
            _toggleNotificationSelection(notification.id);
          });
        },
      ),
    );
  }

  Widget _buildLeadingIcon(model.AppNotification notification) {
    switch (notification.type) {
      case model.NotificationType.productExpiring:
        return const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.warning_amber_rounded, color: Colors.white),
        );
      case model.NotificationType.productExpired:
        return const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.error_outline, color: Colors.white),
        );
      default:
        return const CircleAvatar(
          backgroundColor: Color(0xFF25D366),
          child: Icon(Icons.notifications, color: Colors.white),
        );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min atrás';
    } else {
      return 'Agora mesmo';
    }
  }

  void _toggleNotificationSelection(String id) {
    ref.read(notificationsProvider.notifier).toggleNotificationSelection(id);
  }

  void _selectAll() {
    ref.read(notificationsProvider.notifier).toggleSelectAll();
    setState(() {}); // Força rebuild para atualizar a UI
  }

  void _clearSelected() async {
    final selectedIds = ref
        .read(notificationsProvider.notifier)
        .selectedNotificationIds;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          selectedIds.isEmpty
              ? 'Deseja realmente limpar todas as notificações?'
              : 'Deseja remover as ${selectedIds.length} notificações selecionadas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (selectedIds.isEmpty) {
        await ref.read(notificationsProvider.notifier).clearAllNotifications();
      } else {
        await ref
            .read(notificationsProvider.notifier)
            .removeSelectedNotifications(selectedIds);
      }

      setState(() {
        _isSelecting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedIds.isEmpty
                  ? 'Todas as notificações foram removidas'
                  : '${selectedIds.length} notificações removidas',
            ),
            backgroundColor: const Color(0xFF25D366),
          ),
        );
      }
    }
  }

  void _handleNotificationTap(model.AppNotification notification) {
    ref
        .read(notificationsProvider.notifier)
        .markNotificationRead(notification.id);
    final route = notification.payload?['route'] as String?;
    if (route != null && route.isNotEmpty) {
      Navigator.of(context).pushNamed(route, arguments: notification.payload);
      return;
    }

    if (notification.type == model.NotificationType.productExpiring ||
        notification.type == model.NotificationType.productExpired) {
      final productId = notification.payload?['productId'] as String?;
      if (productId != null) {
        final service = ProductService();
        service
            .getProduct(productId)
            .then((Product product) {
              if (!mounted) return;
              Navigator.pushNamed(
                context,
                '/product-detail',
                arguments: product,
              );
            })
            .catchError((_) {
              // Fallback: abre tela de notificações mesmo assim
            });
      }
    }
  }
}
