import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';
import 'package:desperdicio_zero/widgets/app_button.dart';
import 'package:desperdicio_zero/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService().signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      
      if (mounted) {
        if (response.session != null) {
          Navigator.of(context).pop();
        } else {
          if (mounted) {
            AppSnackbar.showSuccess(
              context: context,
              message: 'Por favor, verifique seu e-mail para confirmar sua conta.',
            );
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context: context,
          message: 'Erro ao cadastrar: $e',
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.food_bank_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Crie sua conta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preencha os dados abaixo para se cadastrar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    
                    AppTextField(
                      controller: _nameController,
                      label: 'Nome completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu e-mail';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Por favor, insira um e-mail válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _passwordController,
                      label: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
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
                    const SizedBox(height: 32),
                    
                    AppButton(
                      text: 'Cadastrar',
                      onPressed: _register,
                      isLoading: _isLoading,
                      borderRadius: 12,
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Já tem uma conta?'),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(
                            'Entrar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
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
      ),
    );
  }
}
