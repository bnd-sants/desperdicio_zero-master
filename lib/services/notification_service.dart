import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/notification_preferences_provider.dart';
import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/services/deep_link_service.dart';
import 'package:desperdicio_zero/services/product_service.dart';

// Tipos de notificações suportados
enum NotificationType {
  productExpiring, // Produto próximo ao vencimento
  productExpired, // Produto vencido
  shoppingList, // Lembretes de lista de compras
  consumptionTip, // Dica de consumo
  weeklySummary, // Resumo semanal
  achievementUnlocked, // Conquista desbloqueada
}

// Modelo para dados da notificação
class NotificationData {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? payload;
  final String? imageUrl;
  final String? actionTitle;
  final String? actionRoute;

  NotificationData({
    required this.type,
    required this.title,
    required this.body,
    this.payload,
    this.imageUrl,
    this.actionTitle,
    this.actionRoute,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'title': title,
      'body': body,
      'payload': payload,
      'imageUrl': imageUrl,
      'actionTitle': actionTitle,
      'actionRoute': actionRoute,
    };
  }

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      type: NotificationType.values[map['type'] as int],
      title: map['title'] as String,
      body: map['body'] as String,
      payload: map['payload'] != null
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : null,
      imageUrl: map['imageUrl'] as String?,
      actionTitle: map['actionTitle'] as String?,
      actionRoute: map['actionRoute'] as String?,
    );
  }

  String toJson() => json.encode(toMap());
  factory NotificationData.fromJson(String source) =>
      NotificationData.fromMap(json.decode(source) as Map<String, dynamic>);
}

class NotificationService with ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  // Private constructor
  NotificationService._internal();

  // Initialize method to be called at app startup
  static Future<NotificationService> initialize() async {
    await _instance._init();
    return _instance;
  }

  late final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  FlutterLocalNotificationsPlugin get _notifications {
    if (!_isInitialized) {
      throw StateError(
        'NotificationService has not been initialized. Call NotificationService.initialize() first.',
      );
    }
    return _notificationsPlugin;
  }

  Future<void> _init() async {
    if (_isInitialized) return;

    try {
      // Initialize timezones with error handling
      try {
        tz.initializeTimeZones();
      } catch (e) {
        debugPrint('Error initializing timezones: $e');
        tz.initializeTimeZones(); // Try again as fallback
      }

      // Initialize the plugin
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

      // Request permissions
      try {
        // For iOS/macOS
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);

        // For Android 13+
        final status = await Permission.notification.request();
        if (status.isDenied) {
          debugPrint('Notification permission denied');
        }
      } catch (e) {
        debugPrint('Error requesting notification permissions: $e');
      }

      // Android settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            defaultPresentAlert: true,
            defaultPresentBadge: true,
            defaultPresentSound: true,
            notificationCategories: <DarwinNotificationCategory>[
              DarwinNotificationCategory(
                'product_actions',
                actions: <DarwinNotificationAction>[
                  DarwinNotificationAction.plain(
                    'view_product',
                    'Ver produto',
                    options: <DarwinNotificationActionOption>{
                      DarwinNotificationActionOption.foreground,
                    },
                  ),
                  DarwinNotificationAction.plain(
                    'dismiss',
                    'Dispensar',
                    options: <DarwinNotificationActionOption>{
                      DarwinNotificationActionOption.destructive,
                    },
                  ),
                ],
              ),
            ],
          );

      final WindowsInitializationSettings initializationSettingsWindows =
          WindowsInitializationSettings(
        appName: 'Desperdício Zero',
        appUserModelId: 'com.example.desperdicio_zero',
        guid: '9D36A9A3-95C8-4ABE-9A3E-7D63F2A0E3B1',
      );

      // Initialize settings for both platforms
      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsIOS,
            windows: initializationSettingsWindows,
          );

      // Initialize the plugin
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            NotificationService.onDidReceiveNotificationResponse,
      );

      _isInitialized = true;
      debugPrint('✅ NotificationService inicializado com sucesso');
    } catch (e, stackTrace) {
      _isInitialized = false;
      debugPrint('❌ Erro ao inicializar NotificationService: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> showPushNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    if (!_isInitialized) {
      await _init();
    }

    const androidDetails = AndroidNotificationDetails(
      'push_messages_channel',
      'Mensagens Push',
      channelDescription: 'Notificações recebidas do servidor',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final payloadJson = payload == null ? null : jsonEncode(payload);

    await _notifications.show(id, title, body, details, payload: payloadJson);
  }

  Future<bool> _requestPermissions() async {
    try {
      // Check current permission status
      var status = await Permission.notification.status;
      debugPrint('Status atual da permissão: ${status.toString()}');

      // If not granted, request it
      if (status.isDenied) {
        debugPrint('Solicitando permissão de notificação...');
        status = await Permission.notification.request();
        debugPrint('Status após solicitação: ${status.toString()}');
      }

      if (status.isPermanentlyDenied) {
        debugPrint(
          'Permissão negada permanentemente, abrindo configurações...',
        );
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    } catch (e, stackTrace) {
      debugPrint('Erro ao verificar/solicitar permissão: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Métodos auxiliares para obter detalhes específicos de cada tipo de notificação
  NotificationDetails _getNotificationDetails(NotificationType type) {
    // Configurações para Android
    AndroidNotificationDetails androidDetails;
    // Configurações para iOS
    DarwinNotificationDetails iosDetails;

    switch (type) {
      case NotificationType.productExpiring:
        androidDetails = const AndroidNotificationDetails(
          'product_expiring_channel',
          'Aviso de Validade',
          channelDescription:
              'Notificações sobre produtos próximos do vencimento',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF25D366), // Verde WhatsApp
          enableLights: true,
          enableVibration: true,
          playSound: true,
          showWhen: true,
          groupKey: 'notifications_products',
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('view_product', 'Ver produto'),
            AndroidNotificationAction('dismiss', 'Dispensar'),
          ],
          styleInformation: BigTextStyleInformation(''),
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );
        break;

      case NotificationType.productExpired:
        androidDetails = const AndroidNotificationDetails(
          'product_expired_channel',
          'Produto Vencido',
          channelDescription: 'Notificações sobre produtos que venceram',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFF3B30), // Vermelho
          enableLights: true,
          enableVibration: true,
          playSound: true,
          showWhen: true,
          groupKey: 'notifications_products',
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('view_product', 'Ver produto'),
            AndroidNotificationAction('dismiss', 'Dispensar'),
          ],
          styleInformation: BigTextStyleInformation(''),
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          badgeNumber: 1,
        );
        break;

      case NotificationType.shoppingList:
        androidDetails = const AndroidNotificationDetails(
          'shopping_list_channel',
          'Lista de Compras',
          channelDescription: 'Lembretes de lista de compras',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF007AFF), // Azul
          enableLights: true,
          enableVibration: false,
          playSound: true,
          showWhen: true,
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        break;

      case NotificationType.consumptionTip:
        androidDetails = const AndroidNotificationDetails(
          'tips_channel',
          'Dicas de Consumo',
          channelDescription: 'Dicas para reduzir o desperdício',
          importance: Importance.low,
          priority: Priority.low,
          enableLights: true,
          enableVibration: false,
          playSound: false,
          showWhen: true,
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        );
        break;

      case NotificationType.weeklySummary:
        androidDetails = const AndroidNotificationDetails(
          'weekly_summary_channel',
          'Resumo Semanal',
          channelDescription: 'Resumo semanal do seu consumo',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF5856D6), // Roxo
          enableLights: true,
          enableVibration: true,
          playSound: true,
          showWhen: true,
          styleInformation: InboxStyleInformation(
            [],
            contentTitle: 'Resumo Semanal',
            summaryText: 'Veja seu resumo de consumo da semana',
          ),
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        break;

      case NotificationType.achievementUnlocked:
        androidDetails = const AndroidNotificationDetails(
          'achievements_channel',
          'Conquistas',
          channelDescription: 'Notificações de conquistas desbloqueadas',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFFCC00), // Amarelo
          enableLights: true,
          enableVibration: true,
          playSound: true,
          showWhen: true,
        );
        iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        break;
    }

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // Agenda uma notificação personalizada
  Future<void> scheduleNotification({
    required int id,
    required NotificationData notificationData,
    required DateTime scheduledDate,
    bool repeatWeekly = false,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDateTZ = tz.TZDateTime.from(scheduledDate, tz.local);

      if (scheduledDateTZ.isBefore(now)) {
        debugPrint('⚠️ Data de agendamento já passou: $scheduledDateTZ');
        return;
      }

      final details = _getNotificationDetails(notificationData.type);

      if (repeatWeekly) {
        // Agenda notificação recorrente semanalmente
        await _notifications.periodicallyShow(
          id,
          notificationData.title,
          notificationData.body,
          RepeatInterval.weekly,
          details,
          payload: notificationData.toJson(),
          androidScheduleMode: AndroidScheduleMode
              .exactAllowWhileIdle, // Permite notificações mesmo em modo de economia de bateria
        );
      } else {
        // Agenda notificação única
        await _notifications.zonedSchedule(
          id,
          notificationData.title,
          notificationData.body,
          scheduledDateTZ,
          details,
          payload: notificationData.toJson(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: repeatWeekly
              ? DateTimeComponents.dayOfWeekAndTime
              : DateTimeComponents.time,
        );
      }

      debugPrint(
        '✅ Notificação agendada com sucesso: ${notificationData.title}',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao agendar notificação: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Configura o manipulador de notificações em segundo plano
  @pragma('vm:entry-point')
  static Future<void> onDidReceiveNotificationResponse(
    NotificationResponse response,
  ) async {
    try {
      if (response.payload != null) {
        final notificationData = NotificationData.fromJson(response.payload!);
        final nav = navigatorKey.currentState;
        if (nav != null) {
          if (response.actionId == 'dismiss') {
            return;
          }
          if (response.actionId == 'view_product') {
            final pid = notificationData.payload?['productId'] as String?;
            if (pid != null && pid.isNotEmpty) {
              try {
                final product = await ProductService().getProduct(pid);
                nav.pushNamed('/product-detail', arguments: product);
                return;
              } catch (_) {}
            }
          }
          final route =
              notificationData.actionRoute ??
              (notificationData.payload != null
                  ? notificationData.payload!['route'] as String?
                  : null);
          if (route != null && route.startsWith('/product/')) {
            final productId = route.split('/product/').last;
            try {
              final product = await ProductService().getProduct(productId);
              nav.pushNamed('/product-detail', arguments: product);
              return;
            } catch (_) {}
          }
          if (route != null && route.isNotEmpty) {
            nav.pushNamed(route, arguments: notificationData.payload);
          } else {
            nav.pushNamed(
              '/notifications',
              arguments: notificationData.payload,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao processar clique na notificação: $e');
    }
  }

  // Verifica se as notificações estão ativadas
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();
    return await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions()
            .then((bool? result) => result ?? false) ??
        false;
  }

  // Gera um ID único baseado no tipo de notificação e parâmetros
  static int _generateNotificationId(
    NotificationType type, {
    String? uniqueKey,
  }) {
    // Usa o hash do tipo de notificação e uma chave única se fornecida
    final uniqueId =
        uniqueKey?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    return (type.index + 1) * 1000000 + (uniqueId % 1000000);
  }

  // Agenda uma notificação recorrente para o resumo semanal
  Future<void> scheduleWeeklySummary({
    required String title,
    required String body,
    required TimeOfDay time,
    List<Map<String, dynamic>>? items,
  }) async {
    final now = DateTime.now();
    // Encontra a próxima ocorrência do dia da semana e hora especificados
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Se já passou do horário hoje, agende para a próxima semana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    final notificationData = NotificationData(
      type: NotificationType.weeklySummary,
      title: title,
      body: body,
      payload: {
        'type': 'weekly_summary',
        'date': scheduledDate.toIso8601String(),
        'items': items,
      },
      actionRoute: '/summary',
    );

    // Gera um ID único baseado no tipo de notificação e data/hora
    final notificationId = _generateNotificationId(
      NotificationType.weeklySummary,
      uniqueKey: 'weekly_${scheduledDate.weekday}_${time.hour}_${time.minute}',
    );

    await scheduleNotification(
      id: notificationId,
      notificationData: notificationData,
      scheduledDate: scheduledDate,
      repeatWeekly: true,
    );
  }

  // Agenda uma notificação de dica de consumo
  Future<void> scheduleConsumptionTip({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? tipId,
  }) async {
    final notificationData = NotificationData(
      type: NotificationType.consumptionTip,
      title: title,
      body: body,
      payload: {
        'type': 'consumption_tip',
        'tipId': tipId,
        'date': scheduledDate.toIso8601String(),
      },
    );

    // Gera um ID único baseado no tipo de notificação e tipId
    final notificationId = _generateNotificationId(
      NotificationType.consumptionTip,
      uniqueKey: tipId ?? 'tip_${scheduledDate.millisecondsSinceEpoch}',
    );

    await scheduleNotification(
      id: notificationId,
      notificationData: notificationData,
      scheduledDate: scheduledDate,
    );
  }

  // Agenda uma notificação para quando um produto estiver próximo do vencimento
  Future<void> scheduleProductNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool repeatWeekly = false,
    String? productId,
    String? productName,
  }) async {
    // Ensure the service is initialized
    if (!_isInitialized) {
      try {
        await NotificationService.initialize();
      } catch (e) {
        debugPrint('❌ Falha ao inicializar o serviço de notificações: $e');
        return;
      }
    }

    try {
      // Inicializa o timezone se ainda não foi inicializado
      tz.initializeTimeZones();

      debugPrint('\n📅 Agendando notificação:');
      debugPrint('Título: $title');
      debugPrint('Mensagem: $body');
      debugPrint('Data agendada: $scheduledDate');

      // Verifica permissões
      debugPrint('Verificando permissões...');
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        debugPrint('❌ Permissão de notificação não concedida');
        return;
      }
      debugPrint('✅ Permissão de notificação concedida');

      // Get current time in local timezone
      final now = tz.TZDateTime.now(tz.local);
      final scheduledDateTZ = tz.TZDateTime.from(scheduledDate, tz.local);

      // If the date has already passed, don't schedule
      if (scheduledDateTZ.isBefore(now)) {
        debugPrint('⚠️ Data de agendamento já passou: $scheduledDateTZ');
        return;
      }

      // Configure notification details for Android
      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'product_expiration_channel',
        'Notificações de Validade',
        channelDescription:
            'Notificações sobre produtos próximos do vencimento',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: false,
      );

      // Configure notification details for iOS
      const iosPlatformChannelSpecifics = DarwinNotificationDetails();

      // Combine platform-specific details
      const notificationDetails = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      // Calculate the duration until the notification should be shown
      final duration = scheduledDateTZ.difference(now);

      // Schedule the notification using a timer
      if (duration > Duration.zero) {
        try {
          // First, cancel any existing notification with the same ID
          await _notifications.cancel(id);

          // Then schedule the new one
          await _notifications.periodicallyShow(
            id,
            title,
            body,
            RepeatInterval.daily,
            notificationDetails,
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('❌ Erro ao manipular notificação: $e');
          rethrow;
        }

        debugPrint(
          '✅ Notificação agendada com sucesso para ${scheduledDateTZ.toString()}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao agendar notificação: $e');
      debugPrint('\n❌❌ ERRO CRÍTICO ao agendar notificação ❌❌');
      debugPrint('Erro: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('====================================\n');
      rethrow;
    }
  }

  Future<void> scheduleProductExpirationNotification({
    required WidgetRef ref,
    required Product product,
    required String title,
    required String body,
    required DateTime expirationDate,
    int daysBefore = 1, // Notificar 1 dia antes por padrão
  }) async {
    final prefs = ref.read(notificationPreferencesProvider);
    final category = product.type ?? 'Outros';
    if (prefs.categoriasSilenciadas.contains(category)) {
      // Usuário optou por não receber alerta para esta categoria
      return;
    }
    final diasAntes = prefs.diasAntes;
    final horario = prefs.horario;
    final expirationDate = product.expirationDate;
    if (expirationDate == null) return;
    final scheduledDate = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
      horario.hour,
      horario.minute,
    ).subtract(Duration(days: diasAntes));

    final notificationData = NotificationData(
      type: NotificationType.productExpiring,
      title: title,
      body: body,
      payload: {
        'type': 'product_expiration',
        'productId': product.id,
        'daysBefore': daysBefore,
        'scheduledAt': scheduledDate.toIso8601String(),
      },
      actionRoute: '/product/${product.id}',
    );

    // Gera um ID único baseado no tipo de notificação e data/hora
    final notificationId = _generateNotificationId(
      NotificationType.productExpiring,
      uniqueKey: 'product_${product.id}_$daysBefore',
    );

    await scheduleNotification(
      id: notificationId,
      notificationData: notificationData,
      scheduledDate: scheduledDate,
    );
  }

  Future<void> scheduleStandardProductNotifications({
    required WidgetRef ref,
    required Product product,
  }) async {
    try {
      await cancelProductNotifications(product.id);

      await scheduleProductExpirationNotification(
        ref: ref,
        product: product,
        title: 'Produto Próximo do Vencimento',
        body: 'O produto ${product.name} está próximo do vencimento!',
        expirationDate: product.expirationDate!,
        daysBefore: 1,
      );

      await scheduleProductExpirationNotification(
        ref: ref,
        product: product,
        title: 'Produto Vencendo Hoje',
        body: 'O produto ${product.name} vence hoje!',
        expirationDate: product.expirationDate!,
        daysBefore: 0,
      );
    } catch (e) {
      debugPrint('Erro ao agendar notificações padrão: $e');
    }
  }

  // Cancela uma notificação específica
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('✅ Notificação $id cancelada com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao cancelar notificação $id: $e');
    }
  }

  // Cancela todas as notificações agendadas
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('✅ Todas as notificações foram canceladas');
    } catch (e) {
      debugPrint('❌ Erro ao cancelar todas as notificações: $e');
    }
  }

  // Cancela notificações de um produto específico
  Future<void> cancelProductNotifications(String productId) async {
    try {
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();
      for (final notification in pendingNotifications) {
        final payload = notification.payload;
        if (payload == null) continue;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          if (data['type'] == 'product_expiration' &&
              data['productId'] == productId) {
            await _notifications.cancel(notification.id);
          }
        } catch (_) {
          if (payload.contains('"productId":"$productId"')) {
            await _notifications.cancel(notification.id);
          }
        }
      }
      debugPrint('Notificações do produto $productId canceladas');
    } catch (e) {
      debugPrint('Erro ao cancelar notificações do produto $productId: $e');
    }
  }

  // Verifica se há notificações pendentes
  Future<bool> hasPendingNotifications() async {
    final pendingNotifications = await _notificationsPlugin
        .pendingNotificationRequests();
    return pendingNotifications.isNotEmpty;
  }

  // Permission handling is now directly in _init() to avoid context dependency
}
