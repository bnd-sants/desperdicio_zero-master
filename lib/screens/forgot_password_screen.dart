import 'package:flutter/material.dart';
import 'package:desperdicio_zero/services/auth_service.dart';
import 'package:desperdicio_zero/widgets/app_card.dart';
import 'package:desperdicio_zero/widgets/app_text_field.dart';
import 'package:desperdicio_zero/widgets/app_button.dart';
import 'package:desperdicio_zero/widgets/app_snackbar.dart';
import 'package:desperdicio_zero/theme/style_tokens.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context: context,
        message: 'Se existir uma conta, um email foi enviado com instruções.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Erro ao solicitar redefinição: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Esqueci a senha'),
        backgroundColor: colorScheme.primary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(StyleTokens.spacingL),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Recuperar acesso',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: StyleTokens.spacingS),
                    Text(
                      'Informe seu e-mail para receber as instruções de redefinição de senha.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: StyleTokens.spacingL),
                    AppTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      hint: 'seuemail@exemplo.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu e-mail';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: StyleTokens.spacingXL),
                    AppButton(
                      text: 'Enviar instruções',
                      onPressed: () {
                        if (_loading) return;
                        _submit();
                      },
                      isLoading: _loading,
                      borderRadius: StyleTokens.radiusM,
                      isFullWidth: true,
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
