import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  final _minimumDuration = const Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Inicia o carregamento dos recursos
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Inicia o timer mínimo de exibição
    final minimumTimer = Future.delayed(_minimumDuration);
    
    // Carrega os recursos necessários
    await Future.wait([
      _checkAuthState(),
      minimumTimer,
    ]);
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return;
    
    final authState = ref.read(authNotifierProvider);
    
    await Future.delayed(const Duration(milliseconds: 500)); // Pequeno delay para a animação
    
    if (!mounted) return;
    
    if (authState is Authenticated) {
      // Usuário autenticado, vai para a tela inicial
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // Usuário não autenticado, vai para o login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    // Substitua o arquivo abaixo pelo seu logo em assets/images/logo.png
                    Image.asset(
                      'assets/images/logo.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Desperdício Zero',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
