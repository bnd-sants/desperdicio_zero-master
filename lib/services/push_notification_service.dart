import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:desperdicio_zero/services/notification_service.dart';
import 'package:desperdicio_zero/services/deep_link_service.dart';
import 'package:desperdicio_zero/services/product_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  String? _cachedToken;

  Future<void> initialize(SupabaseClient supabaseClient) async {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      debugPrint('PushNotificationService: Plataforma não suportada para FCM.');
      return;
    }

    if (_initialized) {
      await syncTokenForCurrentUser(supabaseClient);
      return;
    }

    try {
      await _messaging.setAutoInitEnabled(true);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('PushNotificationService: permissão de push negada.');
        return;
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);

      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen(
            (token) => _upsertToken(supabaseClient, token),
            onError: (error) => debugPrint(
              'PushNotificationService: erro ao atualizar token: $error',
            ),
          );

      await syncTokenForCurrentUser(supabaseClient);
      _initialized = true;
    } catch (e, stackTrace) {
      debugPrint('PushNotificationService: erro ao inicializar: $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> syncTokenForCurrentUser(SupabaseClient supabaseClient) async {
    try {
      String? token;
      if (kIsWeb) {
        final vapidKey = dotenv.env['FIREBASE_VAPID_KEY'];
        token = await _messaging.getToken(vapidKey: vapidKey);
      } else {
        token = await _messaging.getToken();
      }
      if (token == null) return;
      debugPrint(
        'PushNotificationService: token obtido (${kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android')})',
      );
      await _upsertToken(supabaseClient, token);
    } catch (e) {
      debugPrint('PushNotificationService: erro ao sincronizar token: $e');
    }
  }

  Future<void> deleteTokenForCurrentUser(SupabaseClient supabaseClient) async {
    if (_cachedToken == null) return;

    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) return;

      await supabaseClient.from('notification_tokens').delete().match({
        'user_id': userId,
        'token': _cachedToken!,
      });
    } catch (e) {
      debugPrint('PushNotificationService: erro ao remover token: $e');
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }

  Future<void> _upsertToken(SupabaseClient supabaseClient, String token) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      _cachedToken = token;
      return;
    }

    try {
      _cachedToken = token;
      await supabaseClient.from('notification_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
      }, onConflict: 'token');
      debugPrint('PushNotificationService: token sincronizado com Supabase');
    } catch (e) {
      debugPrint('PushNotificationService: erro ao salvar token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await NotificationService.instance.showPushNotification(
      title: notification.title ?? 'Nova notificação',
      body: notification.body ?? '',
      payload: message.data.isEmpty
          ? null
          : Map<String, dynamic>.from(message.data),
    );
  }

  void _handleOpenedApp(RemoteMessage message) {
    debugPrint(
      'PushNotificationService: notificação aberta com payload: ${message.data}',
    );
    final nav = navigatorKey.currentState;
    if (nav != null) {
      final route = (message.data['route'] as String?) ?? '';
      final productId = message.data['productId'] as String?;
      if (route.startsWith('/product/') || productId != null) {
        final id = productId ?? route.split('/product/').last;
        ProductService()
            .getProduct(id)
            .then((product) {
              nav.pushNamed('/product-detail', arguments: product);
            })
            .catchError((_) {
              nav.pushNamed('/notifications', arguments: message.data);
            });
      } else if (route.isNotEmpty) {
        nav.pushNamed(route, arguments: message.data);
      } else {
        nav.pushNamed('/notifications', arguments: message.data);
      }
    }
  }
}
