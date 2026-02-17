import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/services/auth_service.dart';
import 'package:desperdicio_zero/services/telemetry_service.dart';
import 'package:desperdicio_zero/models/user_profile.dart';
import 'package:desperdicio_zero/utils/logger_util.dart';
import 'package:desperdicio_zero/widgets/app_text_field.dart';
import 'package:desperdicio_zero/widgets/app_button.dart';
import 'package:desperdicio_zero/widgets/app_snackbar.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:desperdicio_zero/core/providers/theme/theme_provider.dart';
import 'package:desperdicio_zero/widgets/language_selector.dart';
import 'package:desperdicio_zero/core/providers/gamification_provider.dart';
import 'package:desperdicio_zero/widgets/gamification_widgets.dart';
import 'package:desperdicio_zero/screens/notification_preferences_screen.dart';
import 'package:desperdicio_zero/core/providers/notification_preferences_provider.dart';
import 'package:desperdicio_zero/core/providers/metrics/metrics_provider.dart';
import 'package:desperdicio_zero/core/providers/gamification_events_provider.dart';
import 'package:desperdicio_zero/models/gamification_event.dart';
import 'package:desperdicio_zero/services/local_food_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _avatarUrl;

  Future<void> _refreshMetrics() async {
    try {
      await ref.read(metricsProvider.notifier).refresh();
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context: context,
        message: 'Métricas atualizadas!',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context: context,
        message: 'Falha ao atualizar métricas.',
      );
    }
  }

  Widget _buildMetricHighlight(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(StyleTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(StyleTokens.radiusM),
      ),
      width: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: StyleTokens.spacingS),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: StyleTokens.spacingXS),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, GamificationEvent event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = DateFormat('dd/MM • HH:mm').format(event.createdAt.toLocal());
    final icon = _iconForEvent(event.eventType);
    final lines = <String>[
      if (event.description != null && event.description!.isNotEmpty)
        event.description!,
      if (event.xpChange != 0)
        '${event.xpChange > 0 ? '+' : ''}${event.xpChange} XP',
    ];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: colorScheme.primary),
      ),
      title: Text(
        event.title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: lines.isEmpty
          ? null
          : Text(
              lines.join(' · '),
              style: theme.textTheme.bodySmall,
            ),
      trailing: Text(
        dateLabel,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  IconData _iconForEvent(String type) {
    switch (type) {
      case 'mission_completed':
        return Icons.flag_rounded;
      case 'product_consumed':
        return Icons.restaurant_rounded;
      case 'product_added':
        return Icons.add_shopping_cart_rounded;
      case 'product_discarded':
        return Icons.delete_outline;
      case 'recipe_completed':
        return Icons.menu_book_outlined;
      case 'badge_unlocked':
        return Icons.emoji_events_outlined;
      case 'level_up':
        return Icons.trending_up_rounded;
      case 'xp_gained':
        return Icons.bolt_rounded;
      default:
        return Icons.timeline_rounded;
    }
  }

  void _showPermissionHint() {
    AppSnackbar.showInfo(
      context: context,
      message: 'Verifique as permissões nas configurações do sistema.',
    );
  }

  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await LocalFoodService().clearAll();
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context: context,
        message: 'Cache local limpo!',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context: context,
        message: 'Falha ao limpar o cache.',
      );
    }
  }

  String _buildNotificationSummary(
    BuildContext context,
    NotificationPreferences prefs,
  ) {
    final time = '${prefs.horario.hour.toString().padLeft(2, '0')}:${prefs.horario.minute.toString().padLeft(2, '0')}';
    final pushStatus = prefs.receberPush ? 'ativadas' : 'desativadas';
    final emailStatus = prefs.receberEmails ? 'ativados' : 'desativados';
    final categoriesMuted = prefs.categoriasSilenciadas.isEmpty
        ? 'Nenhuma categoria silenciada'
        : '${prefs.categoriasSilenciadas.length} categorias silenciadas';

    return 'Alertar ${prefs.diasAntes} dias antes às $time · Push $pushStatus · E-mails $emailStatus · $categoriesMuted';
  }

  String _resolveDisplayName(User? user, UserProfile? profile) {
    final candidates = <String?>[
      profile?.fullName,
      user?.userMetadata?['full_name'] as String?,
      user?.email?.split('@').first,
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return 'Usuário';
  }

  String? _resolveAvatarUrl(User? user, UserProfile? profile) {
    final candidates = <String?>[
      profile?.avatarUrl,
      user?.userMetadata?['avatar_url'] as String?,
      _avatarUrl,
    ];

    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authService = ref.read(AuthService.provider);
      final user = authService.currentUser;
      final profile = await authService.getCurrentUserProfile();

      if (!mounted) return;
      setState(() {
        _nameController.text = _resolveDisplayName(user, profile);
        _avatarUrl = _resolveAvatarUrl(user, profile);
      });
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Erro ao carregar perfil', e, stackTrace);
      await TelemetryService.logEvent(
        category: 'profile',
        severity: 'error',
        message: 'Falha ao carregar perfil',
        data: {'error': e.toString()},
      );
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Não foi possível carregar seu perfil. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Inicializa a variável status com um valor padrão
      PermissionStatus status = PermissionStatus.denied;
      bool shouldContinue = false;

      // Se for web, não precisa de permissão
      if (kIsWeb) {
        shouldContinue = true;
      } 
      // Para Android
      else if (Platform.isAndroid) {
        // Tenta obter permissão de fotos (Android 13+)
        if (await Permission.photos.isGranted) {
          status = PermissionStatus.granted;
          shouldContinue = true;
        } else {
          // Se não tiver permissão, solicita
          status = await Permission.photos.request();
          shouldContinue = status.isGranted;

          // Se negado, tenta com storage (para versões mais antigas)
          if (status.isDenied) {
            status = await Permission.storage.request();
            shouldContinue = status.isGranted;
          }
        }
      } 
      // Para iOS
      else if (Platform.isIOS) {
        status = await Permission.photos.request();
        shouldContinue = status.isGranted;
      }

      // Se a permissão foi negada, mostra mensagem
      if (!shouldContinue) {
        if (status.isPermanentlyDenied) {
          // Se o usuário marcou "nunca perguntar novamente"
          if (!mounted) return;
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permissão necessária'),
              content: const Text(
                'Para alterar sua foto de perfil, por favor, permita o acesso à galeria nas configurações do aplicativo.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Abrir configurações'),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        } else {
          // Se foi negada, mostra aviso
          if (mounted) {
            AppSnackbar.showWarning(
              context: context,
              message:
                  'Permissão para acessar a galeria é necessária para alterar a foto de perfil.',
            );
          }
        }
        return;
      }

      // Se chegou aqui, pode prosseguir com a seleção da imagem
      final picker = image_picker.ImagePicker();
      final pickedFile = await picker.pickImage(
        source: image_picker.ImageSource.gallery,
        imageQuality: 85, // Qualidade reduzida para melhor performance
        maxWidth: 800,   // Largura máxima
        maxHeight: 800,  // Altura máxima
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() => _isSaving = true);

        try {
          final authService = ref.read(AuthService.provider);
          final avatarUrl = await authService.uploadAvatar(pickedFile.path);

          if (!mounted) return;
          setState(() {
            _avatarUrl = avatarUrl;
            _isSaving = false;
          });

          if (mounted) {
            AppSnackbar.showSuccess(
              context: context,
              message: 'Foto de perfil atualizada com sucesso!',
            );
          }
        } catch (e) {
          LoggerUtil.logger.severe('Erro ao fazer upload da imagem', e);
          if (mounted) {
            setState(() => _isSaving = false);
            AppSnackbar.showError(
              context: context,
              message: 'Erro ao atualizar a foto de perfil. Tente novamente.',
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isSaving = false);
          }
        }
      }
    } catch (e) {
      LoggerUtil.logger.severe('Erro ao acessar a galeria', e);
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Não foi possível acessar a galeria. Tente novamente.',
        );
      }
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!mounted || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authService = ref.read(AuthService.provider);
      final trimmedName = _nameController.text.trim();
      if (trimmedName.isEmpty) {
        throw Exception('O nome não pode estar vazio.');
      }

      final updatedProfile = await authService.updateProfile(
        fullName: trimmedName,
        avatarUrl: _avatarUrl,
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _nameController.text = updatedProfile.fullName;
        _avatarUrl = _resolveAvatarUrl(authService.currentUser, updatedProfile) ?? _avatarUrl;
      });

      await TelemetryService.logEvent(
        category: 'profile',
        severity: 'info',
        message: 'Perfil atualizado',
        data: {
          'userId': updatedProfile.id,
          'hasAvatar': (_avatarUrl ?? '').isNotEmpty,
        },
      );

      if (mounted) {
        AppSnackbar.showSuccess(
          context: context,
          message: 'Perfil atualizado com sucesso!',
        );
      }
    } catch (e, stackTrace) {
      LoggerUtil.logger.severe('Erro ao atualizar perfil', e, stackTrace);
      await TelemetryService.logEvent(
        category: 'profile',
        severity: 'error',
        message: 'Falha ao atualizar perfil',
        data: {'error': e.toString()},
      );

      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackbar.showError(
          context: context,
          message: 'Erro ao atualizar perfil. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFE1E1E1),
      child: const Center(
        child: Icon(
          Icons.person,
          size: 50,
          color: Color(0xFF7B7B7B),
        ),
      ),
    );
  }

  Widget _buildGamificationBadges(
    BuildContext context,
    GamificationState gamification,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GamificationXpHeader(
          title: 'Seu Progresso',
          subtitle: 'Continue ajudando o planeta!',
          level: gamification.currentLevel,
          xpCurrent: gamification.xpTotal,
          xpNextLevel: gamification.xpNextLevel,
        ),
        const SizedBox(height: StyleTokens.spacingM),
        BadgeGrid(badges: gamification.badges),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gamification = ref.watch(gamificationProvider);
    final notificationPrefs = ref.watch(notificationPreferencesProvider);
    final notificationNotifier = ref.read(notificationPreferencesProvider.notifier);
    final metricsAsync = ref.watch(metricsProvider);
    final eventsAsync = ref.watch(gamificationEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(StyleTokens.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: StyleTokens.spacingL),
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      _avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildDefaultAvatar();
                                      },
                                    )
                                  : _buildDefaultAvatar(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: colorScheme.onPrimary,
                                ),
                                onPressed: _isSaving ? null : _pickImage,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingXL),
                    AppCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações do Perfil',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: StyleTokens.spacingL),
                            AppTextField(
                              controller: _nameController,
                              label: 'Nome Completo',
                              hint: 'Digite seu nome completo',
                              prefixIcon: const Icon(Icons.person_outline),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite seu nome';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    // Seção de Configurações
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: StyleTokens.spacingL,
                        vertical: StyleTokens.spacingM,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurações',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: StyleTokens.spacingS),
                          Consumer(
                            builder: (context, ref, _) {
                              final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
                              return ListTile(
                                title: Text(
                                  isDarkMode ? 'Modo Escuro' : 'Modo Claro',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                leading: Icon(
                                  isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                                  color: colorScheme.primary,
                                ),
                                trailing: Switch(
                                  value: isDarkMode,
                                  onChanged: (value) {
                                    ref.read(themeProvider.notifier).toggleTheme();
                                  },
                                  activeThumbColor: colorScheme.primary,
                                  activeTrackColor: colorScheme.primaryContainer,
                                  inactiveThumbColor: colorScheme.onSurfaceVariant,
                                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                                ),
                              );
                            },
                          ),
                          ListTile(
                            title: Text(
                              'Idioma',
                              style: TextStyle(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            leading: Icon(
                              Icons.language,
                              color: colorScheme.primary,
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Selecionar Idioma'),
                                  content: const LanguageSelector(),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.notifications_active_outlined),
                            title: Text('Notificações'),
                            subtitle: Text('Configurar alertas e lembretes do app'),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => NotificationPreferencesScreen(),
                              ));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    AppCard(
                      padding: const EdgeInsets.all(StyleTokens.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumo de Notificações',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: StyleTokens.spacingS),
                          Text(
                            _buildNotificationSummary(context, notificationPrefs),
                            style: theme.textTheme.bodySmall,
                          ),
                          const Divider(height: StyleTokens.spacingXL),
                          SwitchListTile.adaptive(
                            value: notificationPrefs.receberPush,
                            onChanged: notificationNotifier.setReceberPush,
                            title: const Text('Receber notificações push'),
                            subtitle: const Text('Alertas diretos no dispositivo'),
                            secondary: const Icon(Icons.notifications_none),
                          ),
                          SwitchListTile.adaptive(
                            value: notificationPrefs.receberEmails,
                            onChanged: notificationNotifier.setReceberEmails,
                            title: const Text('Receber e-mails'),
                            subtitle: const Text('Relatórios e dicas semanais'),
                            secondary: const Icon(Icons.mail_outline),
                          ),
                          SwitchListTile.adaptive(
                            value: notificationPrefs.notificacaoMotivacional,
                            onChanged: notificationNotifier.setMotivacional,
                            title: const Text('Notificações motivacionais'),
                            subtitle: const Text('Mensagens para manter o ritmo'),
                            secondary: const Icon(Icons.emoji_emotions_outlined),
                          ),
                          const SizedBox(height: StyleTokens.spacingS),
                          if (notificationPrefs.categoriasSilenciadas.isNotEmpty)
                            Wrap(
                              spacing: StyleTokens.spacingS,
                              runSpacing: StyleTokens.spacingS,
                              children: notificationPrefs.categoriasSilenciadas
                                  .map(
                                    (cat) => Chip(
                                      label: Text(cat),
                                      avatar: const Icon(Icons.volume_off, size: 16),
                                    ),
                                  )
                                  .toList(),
                            )
                          else
                            Text(
                              'Nenhuma categoria silenciada.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    AppCard(
                      padding: const EdgeInsets.all(StyleTokens.spacingL),
                      child: metricsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estatísticas pessoais',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: StyleTokens.spacingS),
                            Text(
                              'Não foi possível carregar suas métricas.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        data: (snapshot) {
                          if (snapshot == null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estatísticas pessoais',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: StyleTokens.spacingS),
                                Text(
                                  'Faça login para acompanhar seus avanços.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            );
                          }

                          final productMetrics = snapshot.productMetrics;
                          final gamificationSummary = snapshot.gamificationSummary;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estatísticas pessoais',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: StyleTokens.spacingS),
                              Wrap(
                                spacing: StyleTokens.spacingL,
                                runSpacing: StyleTokens.spacingM,
                                children: [
                                  if (productMetrics != null)
                                    _buildMetricHighlight(
                                      context,
                                      icon: Icons.inventory_rounded,
                                      label: 'Itens ativos',
                                      value: productMetrics.activeItems.toString(),
                                    ),
                                  if (productMetrics != null)
                                    _buildMetricHighlight(
                                      context,
                                      icon: Icons.check_circle_outline,
                                      label: 'Consumidos',
                                      value: productMetrics.consumedItems.toString(),
                                    ),
                                  if (gamificationSummary != null)
                                    _buildMetricHighlight(
                                      context,
                                      icon: Icons.star_outline,
                                      label: 'Nível',
                                      value: gamificationSummary.currentLevel.toString(),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    AppCard(
                      padding: const EdgeInsets.all(StyleTokens.spacingL),
                      child: eventsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Histórico de atividades',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: StyleTokens.spacingS),
                            Text(
                              'Não foi possível carregar o histórico agora.',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: StyleTokens.spacingM),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  ref.read(gamificationEventsProvider.notifier).refresh(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                        data: (events) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Histórico de atividades',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        ref.read(gamificationEventsProvider.notifier).refresh(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Atualizar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: StyleTokens.spacingS),
                              if (events.isEmpty)
                                Text(
                                  'Nenhuma atividade registrada ainda. Conclua missões, consuma produtos ou desbloqueie badges para começar!',
                                  style: theme.textTheme.bodySmall,
                                )
                              else
                                ...events
                                    .take(5)
                                    .map((event) => _buildEventTile(context, event)),
                              if (events.length > 5)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: StyleTokens.spacingS),
                                  child: Text(
                                    'Mostrando as 5 mais recentes.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    AppCard(
                      padding: const EdgeInsets.all(StyleTokens.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ações rápidas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: StyleTokens.spacingS),
                          Wrap(
                            spacing: StyleTokens.spacingM,
                            runSpacing: StyleTokens.spacingM,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _refreshMetrics,
                                icon: const Icon(Icons.sync),
                                label: const Text('Sincronizar dados'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _clearLocalCache,
                                icon: const Icon(Icons.cleaning_services_outlined),
                                label: const Text('Limpar cache local'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showPermissionHint,
                                icon: const Icon(Icons.security),
                                label: const Text('Rever permissões'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingXL),
                    _buildGamificationBadges(context, gamification),
                    const SizedBox(height: StyleTokens.spacingXL),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: StyleTokens.spacingM),
                      child: AppButton(
                        text: 'Salvar Alterações',
                        onPressed: _saveProfile,
                        isLoading: _isSaving,
                        isFullWidth: true,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    // Botão de Sair
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: StyleTokens.spacingM),
                      child: AppButton(
                        text: 'Sair da Conta',
                        onPressed: () async {
                          // Store context before any async operations
                          final currentContext = context;
                          final theme = Theme.of(currentContext);
                          
                          final shouldLogout = await showDialog<bool>(
                            context: currentContext,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Sair'),
                              content: const Text('Tem certeza que deseja sair da sua conta?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: Text('Sair', style: TextStyle(color: theme.colorScheme.error)),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            try {
                              final authService = ref.read(AuthService.provider);
                              await authService.signOut();
                              
                              if (!currentContext.mounted) return;
                              Navigator.of(currentContext)
                                  .pushNamedAndRemoveUntil('/login', (route) => false);
                            } catch (e) {
                              LoggerUtil.logger.severe('Erro ao fazer logout', e);
                              if (currentContext.mounted) {
                                AppSnackbar.showError(
                                  context: currentContext,
                                  message: 'Erro ao fazer logout. Tente novamente.',
                                );
                              }
                            }
                          }
                        },
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                        textColor: Theme.of(context).colorScheme.onErrorContainer,
                        elevation: 2,
                        isFullWidth: true,
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingXL),
                  ],
                ),
              ),
            ),
    );
  }
}
