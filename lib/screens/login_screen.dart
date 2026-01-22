import 'package:flutter/material.dart';
import 'package:desperdicio_zero/core/providers/index.dart';
import 'package:desperdicio_zero/widgets/app_button.dart';
import 'package:desperdicio_zero/widgets/app_text_field.dart';
import 'package:desperdicio_zero/widgets/app_snackbar.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira seu e-mail';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Por favor, insira um e-mail válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira sua senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      _navigateToHome();
    } catch (e) {
      String errorMessage = 'Ocorreu um erro ao fazer login';
      
      if (e.toString().contains('user-not-found') || 
          e.toString().contains('wrong-password')) {
        errorMessage = 'E-mail ou senha inválidos';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Muitas tentativas. Tente novamente mais tarde.';
      }
      
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(StyleTokens.spacingL),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Title
                  Icon(
                    Icons.food_bank_rounded,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: StyleTokens.spacingL),
                  Text(
                    'Bem-vindo de volta!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: StyleTokens.spacingS),
                  Text(
                    'Faça login para continuar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: StyleTokens.spacingXL),

                  // Login Form
                  AppCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: 'E-mail',
                            hint: 'seuemail@exemplo.com',
                            prefixIcon: const Icon(Icons.email_rounded),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              FocusScope.of(context).requestFocus(_passwordFocus);
                            },
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: StyleTokens.spacingL),
                          AppTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _obscurePassword,
                            label: 'Senha',
                            hint: 'Sua senha',
                            prefixIcon: const Icon(Icons.lock_rounded),
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
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: StyleTokens.spacingXL),
                          AppButton(
                            text: 'Entrar',
                            onPressed: _login,
                            isLoading: _isLoading,
                            borderRadius: StyleTokens.radiusM,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/forgot-password');
                            },
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Esqueceu sua senha?',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Register Link
                  const SizedBox(height: StyleTokens.spacingXL),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Não tem uma conta?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/register');
                        },
                        child: Text(
                          'Cadastre-se',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}