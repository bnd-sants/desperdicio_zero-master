import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:desperdicio_zero/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' as logger;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:desperdicio_zero/screens/recipes/recipes_screen.dart';
import 'package:desperdicio_zero/screens/missions_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'dart:async';

// Services
import 'package:desperdicio_zero/services/deep_link_service.dart';
import 'package:desperdicio_zero/services/notification_service.dart';
import 'package:desperdicio_zero/services/error_monitoring_service.dart';
import 'package:desperdicio_zero/services/telemetry_service.dart';
import 'package:desperdicio_zero/services/push_notification_service.dart';
import 'package:desperdicio_zero/services/database_init_service.dart';

// Screens
import 'package:desperdicio_zero/screens/login_screen.dart';
import 'package:desperdicio_zero/screens/register_screen.dart';
import 'package:desperdicio_zero/screens/forgot_password_screen.dart';
import 'package:desperdicio_zero/screens/reset_password_screen.dart';
import 'package:desperdicio_zero/screens/product_detail_screen.dart';
import 'package:desperdicio_zero/screens/add_product/add_product_screen.dart';
import 'package:desperdicio_zero/screens/calendar_screen.dart';
import 'package:desperdicio_zero/screens/profile_screen.dart';
import 'package:desperdicio_zero/screens/statistics_screen.dart';
import 'package:desperdicio_zero/screens/home/home_screen.dart';
import 'package:desperdicio_zero/screens/notifications_screen.dart';
import 'package:desperdicio_zero/core/utils/secure_storage.dart';

// Config & Models
import 'package:desperdicio_zero/config/supabase_config.dart';
import 'package:desperdicio_zero/core/providers/index.dart';
import 'package:desperdicio_zero/models/product_model.dart';

// Utils & Theme

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final notification = message.notification;
  if (notification == null) return;

  await NotificationService.initialize();
  await NotificationService.instance.showPushNotification(
    title: notification.title ?? 'Nova notificação',
    body: notification.body ?? '',
    payload: message.data.isEmpty
        ? null
        : Map<String, dynamic>.from(message.data),
  );
}

// Função principal assíncrona para inicializar recursos
Future<void> main() async {
  await ErrorMonitoringService.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    logger.LoggerUtil.initialize();
    ErrorMonitoringService.initialize();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Carrega as variáveis de ambiente
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa o Supabase com a nova configuração
  await SupabaseConfig.initialize();

  // Obtém a instância do cliente Supabase
  final supabase = Supabase.instance.client;

  // Verifica se o cliente foi inicializado corretamente
  if (kDebugMode) {
    print('🔵 Cliente Supabase inicializado:');
    print('🔵 Usuário logado: ${supabase.auth.currentUser?.email ?? "Nenhum"}');
  }

  // Inicializa o banco de dados local
  try {
    await DatabaseInitService().initializeDatabase();
    logger.logInfo('Banco de dados local inicializado com sucesso!');
  } catch (e) {
    logger.logError('Erro ao inicializar o banco de dados local: $e', e);
  }

  // Configura o redirecionamento para autenticação
  final redirectUrl =
      '${Uri.base.scheme}://${Uri.base.host}${Uri.base.port != 80 ? ':${Uri.base.port}' : ''}/auth/callback';
  logger.logDebug('URL de redirecionamento: $redirectUrl');

  // Inicializa o serviço de notificações
  if (!kIsWeb) {
  try {
    // Configura o manipulador de notificações em segundo plano
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'Notificações Importantes', // title
      description: 'Este canal é usado para notificações importantes.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Inicializa o serviço de notificações
    final notificationService = await NotificationService.initialize();

    // Configura o canal para Android
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Verifica e solicita permissões se necessário
    final hasPermission = await notificationService.areNotificationsEnabled();
    if (!hasPermission) {
      logger.logDebug('Permissão de notificação não concedida');
    }

    // Agenda notificações de exemplo (opcional)
    // await _scheduleExampleNotifications(notificationService);

    logger.logInfo('✅ Serviço de notificações inicializado com sucesso');

    await PushNotificationService.instance.initialize(supabase);
  } catch (e, stackTrace) {
    logger.logError(
      'Erro ao inicializar serviço de notificações: $e',
      e,
      stackTrace,
    );
    // Continue mesmo se a inicialização das notificações falhar
    logger.logDebug('O aplicativo continuará sem notificações');
  }
  }

  // Configura o listener de mudanças de autenticação
  final authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    final session = data.session;
    logger.logDebug(
      'Auth event: $event, session: ${session != null ? 'present' : 'empty'}',
    );

    if (event == AuthChangeEvent.signedIn && session != null) {
      final email = session.user.email ?? "E-mail não disponível";
      logger.logInfo('Usuário autenticado: $email');
      if (!kIsWeb) {
        unawaited(
          PushNotificationService.instance.syncTokenForCurrentUser(supabase),
        );
      }
    } else if (event == AuthChangeEvent.signedOut) {
      logger.logInfo('Usuário deslogado');
      if (!kIsWeb) {
        unawaited(
          PushNotificationService.instance.deleteTokenForCurrentUser(supabase),
        );
      }
    } else if (event == AuthChangeEvent.passwordRecovery) {
      logger.logInfo('Recuperação de senha solicitada');
    } else if (event == AuthChangeEvent.userUpdated) {
      logger.logInfo('Usuário atualizado');
    }
  });

  // Garante que a inscrição seja cancelada quando o aplicativo for encerrado
  // O estado da autenticação será gerenciado pelo AuthNotifier dentro do ProviderScope

  // Inicializa o logger
  logger.logDebug('Inicializando aplicativo...');

  // Configura o logging
  if (kDebugMode) {
    // Configurações adicionais de debug podem ser adicionadas aqui
    logger.logDebug('Modo debug ativado');
  }

    await TelemetryService.logEvent(
      category: 'app',
      severity: 'info',
      message: 'Bootstrap concluído',
      data: {
        'debug': kDebugMode,
        'web': kIsWeb,
      },
    );

    runApp(const ProviderScope(child: MyApp()));

    // Cancela a inscrição quando o app for encerrado
    await authStateSubscription.cancel();
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final DeepLinkService _deepLinkService;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void dispose() {
    // Cancela a inscrição do deep link quando o widget for descartado
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Aguarda o MaterialApp estar completamente montado
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _maybeShowOnboarding();
        }
      });
    });
  }

  Future<void> _initDeepLinking() async {
    _deepLinkService = DeepLinkService();
    await _deepLinkService.initialize();

    // Listen to deep links while app is running
    _linkSubscription = _deepLinkService.linkStream.listen(_handleDeepLink);
  }

  Future<void> _maybeShowOnboarding() async {
    // Verifica se o contexto ainda é válido antes de tentar mostrar o diálogo
    if (!mounted || navigatorKey.currentContext == null) return;

    final storage = const SecureStorage();
    final prefsDone = await storage
        .getRefreshToken(); // proxy; absence implies first run
    if (prefsDone != null) return;
    if (!mounted) return;
    
    try {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) {
        return AlertDialog(
          title: const Text('Bem-vindo'),
          content: const Text(
            'Ative notificações para receber alertas de validade e dicas.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await storage.saveRefreshToken('onboarding_done');
                navigatorKey.currentState?.pop();
              },
              child: const Text('Agora não'),
            ),
            TextButton(
              onPressed: () async {
                await NotificationService.initialize();
                await storage.saveRefreshToken('onboarding_done');
                navigatorKey.currentState?.pop();
              },
              child: const Text('Ativar notificações'),
            ),
          ],
        );
      },
    );
    } catch (e) {
      // Silently fail - não é crítico se o onboarding não aparecer
      print('Erro ao mostrar onboarding: $e');
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    logger.LoggerUtil.logger.info('Deep link received in main: $uri');

    if (!mounted) return;

    try {
      // Handle password reset deep links (from email)
      if (uri.host == 'reset-password' ||
          uri.host == 'recover' ||
          uri.path.contains('auth/v1/verify')) {
        logger.LoggerUtil.logger.info('Handling password reset deep link');

        String? token;
        String? type;

        // Check for token in query parameters (common for custom schemes)
        token = uri.queryParameters['token'];

        // If not in query parameters, check URL fragment (common for Supabase)
        if (token == null && uri.fragment.isNotEmpty) {
          final params = Uri.splitQueryString(uri.fragment);
          token = params['access_token'] ?? params['token'];
          type = params['type']; // 'recovery' for password reset
        }

        // If still no token, check if it's in the path
        if (token == null && uri.pathSegments.isNotEmpty) {
          final lastSegment = uri.pathSegments.last;
          if (lastSegment.length > 20) {
            // Simple check if it looks like a token
            token = lastSegment;
            type = 'recovery';
          }
        }

        logger.LoggerUtil.logger.info(
          'Token: ${token != null ? 'present' : 'missing'}, Type: $type',
        );

        if (token != null && (type == 'recovery' || type == 'email_change')) {
          // Navigate to reset password screen with the token
          if (navigatorKey.currentState?.mounted ?? false) {
            navigatorKey.currentState!.pushNamedAndRemoveUntil(
              '/reset-password',
              (route) => false,
              arguments: {'token': token},
            );
          }
        } else if (token != null && type == 'signup') {
          // Email confirmation
          logger.LoggerUtil.logger.info('Email confirmation link opened');
          // You can add email confirmation logic here if needed
        } else if (uri.host == 'login-callback' ||
            uri.host == 'confirm-email') {
          logger.LoggerUtil.logger.info(
            'Login/confirmation callback received, handling auth state change',
          );
          // The DeepLinkService will handle this
        } else {
          logger.LoggerUtil.logger.warning('No valid token found in deep link');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Link de redefinição inválido. Por favor, solicite um novo link.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      logger.LoggerUtil.logger.severe(
        'Error handling deep link: $uri',
        e,
        stackTrace,
      );
      // Show error to user if possible
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar o link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Desperdício Zero',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      locale: ref.watch(languageProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      theme: themeMode == ThemeMode.dark
          ? ThemeData(
              colorScheme: ColorScheme.dark(
                primary: Colors.green[300]!,
                primaryContainer: Colors.green[900]!,
                secondary: Colors.lightGreen[300]!,
                secondaryContainer: Colors.lightGreen[900]!,
                surface: Colors.grey[900]!,
                error: Colors.red[400]!,
                onPrimary: Colors.black87,
                onSecondary: Colors.black87,
                onSurface: Colors.white,
                onError: Colors.black87,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.grey[800],
                clipBehavior: Clip.antiAlias,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green[900],
                elevation: 0,
                centerTitle: true,
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.green[300]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                hintStyle: TextStyle(color: Colors.grey[400]),
                labelStyle: TextStyle(color: Colors.grey[300]),
              ),
            )
          : ThemeData(
              colorScheme: ColorScheme.light(
                primary: Colors.green[700]!,
                primaryContainer: Colors.green[100]!,
                secondary: Colors.lightGreen[700]!,
                secondaryContainer: Colors.lightGreen[100]!,
                surface: Colors.white,
                error: Colors.red[700]!,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: Colors.black87,
                onError: Colors.white,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authNotifierProvider);
                  return authState.maybeWhen(
                    authenticated: (_) => const HomeScreen(),
                    orElse: () => const LoginScreen(),
                  );
                },
              ),
            );
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            );
          case '/forgot-password':
            return MaterialPageRoute(
              builder: (context) => const ForgotPasswordScreen(),
            );
          case '/reset-password':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) =>
                  ResetPasswordScreen(token: args?['token'] as String?),
            );
          case '/recipes':
            return MaterialPageRoute(
              builder: (context) => const RecipesScreen(),
            );
          case '/missions':
            return MaterialPageRoute(
              builder: (context) => const MissionsScreen(),
            );
          case '/notifications':
            return MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            );
          case '/product-detail':
            final product = settings.arguments as Product;
            return MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                product: product,
                onEdit: () {
                  Navigator.pushNamed(
                    context,
                    '/add-product',
                    arguments: product,
                  );
                },
              ),
            );
          case '/add-product':
            final product = settings.arguments as Product?;
            return MaterialPageRoute(
              builder: (context) => AddProductScreen(productToEdit: product),
            );
          case '/calendar':
            return MaterialPageRoute(
              builder: (context) => const CalendarScreen(),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
            );
          case '/statistics':
            return MaterialPageRoute(
              builder: (context) => const StatisticsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('Rota ${settings.name} não encontrada'),
                ),
              ),
            );
        }
      },
    );
  }
}
