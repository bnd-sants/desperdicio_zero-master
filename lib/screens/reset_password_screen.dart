import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' as logger;
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/widgets/app_text_field.dart';
import 'package:desperdicio_zero/widgets/app_button.dart';
import 'package:desperdicio_zero/widgets/app_snackbar.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;  // The reset token from the deep link
  final bool isEmailChange;

  const ResetPasswordScreen({
    super.key,
    this.token,
    this.isEmailChange = false,
  });

  @override
  ResetPasswordScreenState createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    logger.LoggerUtil.logger.fine('ResetPasswordScreen initialized with token: ${widget.token != null ? 'present' : 'not present'}');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final password = _passwordController.text.trim();
      
      if (widget.token != null) {
        await _resetPasswordWithToken(widget.token!, password);
      } else {
        await _updatePassword(password);
      }
      
      if (mounted) {
        AppSnackbar.showSuccess(
          context: context,
          message: widget.isEmailChange ? 'E-mail alterado com sucesso!' : 'Senha redefinida com sucesso!',
        );
        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      logger.LoggerUtil.logger.severe('Auth error resetting password', e);
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: _getErrorMessage(e),
        );
      }
    } catch (e, stackTrace) {
      logger.LoggerUtil.logger.severe('Error resetting password', e, stackTrace);
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Ocorreu um erro inesperado. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _resetPasswordWithToken(String token, String newPassword) async {
    try {
      final supabase = Supabase.instance.client;
      
      // First, set the session using the recovery token
      await supabase.auth.setSession(token);
      
      // Then update the password
      final response = await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      if (response.user == null) {
        throw Exception('Falha ao atualizar a senha. Tente novamente.');
      }
      
      logger.LoggerUtil.logger.info('Password reset successfully');
    } catch (e, stackTrace) {
      logger.LoggerUtil.logger.severe('Error in _resetPasswordWithToken', e, stackTrace);
      rethrow;
    }
  }
  
  Future<void> _updatePassword(String newPassword) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      logger.LoggerUtil.logger.info('Password updated successfully');
    } catch (e, stackTrace) {
      logger.LoggerUtil.logger.severe('Error in _updatePassword', e, stackTrace);
      rethrow;
    }
  }
  
  String _getErrorMessage(AuthException e) {
    logger.LoggerUtil.logger.warning('Auth error: ${e.message}');
    
    if (e.message.contains('invalid_token') || 
        e.message.contains('invalid_refresh_token') ||
        e.message.contains('token_expired')) {
      return 'Link de redefinição inválido ou expirado. Por favor, solicite um novo link.';
    } else if (e.message.contains('password')) {
      return 'A senha fornecida não atende aos requisitos mínimos.';
    } else if (e.message.contains('network')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    } else if (e.message.contains('too_many_requests')) {
      return 'Muitas tentativas. Por favor, aguarde um momento antes de tentar novamente.';
    } else if (e.message.contains('weak_password')) {
      return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
    } else if (e.message.contains('user_not_found')) {
      return 'Usuário não encontrado.';
    } else {
      return 'Erro ao redefinir senha: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(StyleTokens.spacingL),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crie uma nova senha',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: StyleTokens.spacingS),
                    Text(
                      'Sua nova senha deve ser diferente da senha usada anteriormente.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingXL),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Nova senha',
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira uma senha';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar nova senha',
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_person_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, confirme sua senha';
                        }
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: StyleTokens.spacingXL),
                    AppButton(
                      text: 'Redefinir senha',
                      onPressed: () {
                        if (_isLoading) return;
                        _resetPassword();
                      },
                      isLoading: _isLoading,
                      borderRadius: StyleTokens.radiusM,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
