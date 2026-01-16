import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class EatingLoader extends StatefulWidget {
  final int maxBowls;
  final String loadingText;
  final VoidCallback? onTap;
  final double size;

  const EatingLoader({
    super.key,
    this.maxBowls = 5,
    this.loadingText = 'Carregando receitas...',
    this.onTap,
    this.size = 150.0,
  });

  @override
  EatingLoaderState createState() => EatingLoaderState();
}

class EatingLoaderState extends State<EatingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentBowls = 0;
  final Random _random = Random();
  bool _isEating = false;
  double _eatProgress = 0.0;
  Timer? _eatingTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _startLoading();
  }

  void _startLoading() {
    // Simula o progresso de carregamento
    const duration = Duration(milliseconds: 500);
    _eatingTimer = Timer.periodic(duration, (timer) {
      if (_eatProgress >= 1.0) {
        setState(() {
          _currentBowls = (_currentBowls + 1) % (widget.maxBowls + 1);
          _eatProgress = 0.0;
        });
      } else {
        setState(() {
          _eatProgress += 0.1 + _random.nextDouble() * 0.2;
          if (_eatProgress > 1.0) _eatProgress = 1.0;
        });
      }
    });
  }

  void _handleTap() {
    setState(() {
      _isEating = !_isEating;
      if (_isEating) {
        _controller.repeat();
      } else {
        _controller.stop();
      }

      // Acelera o carregamento quando toca
      _eatProgress += 0.3;
      if (_eatProgress >= 1.0) {
        _currentBowls = (_currentBowls + 1) % (widget.maxBowls + 1);
        _eatProgress = 0.0;
      }

      widget.onTap?.call();
    });
  }

  @override
  void dispose() {
    _eatingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Personagem
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -5 * _animation.value),
                    child: Icon(
                      _isEating
                          ? Icons.emoji_emotions
                          : Icons.emoji_emotions_outlined,
                      size: widget.size * 0.6,
                      color: isDark ? primaryColor : Colors.orange[700],
                    ),
                  );
                },
              ),

              // Mão com colher
              Positioned(
                right: widget.size * 0.2,
                bottom: widget.size * 0.3,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _isEating
                          ? -0.3 * (1 - _animation.value) * 2
                          : -0.3,
                      child: Icon(
                        Icons.restaurant,
                        size: widget.size * 0.3,
                        color: isDark
                            ? primaryColor.withValues(alpha: 0.8)
                            : Colors.brown[700],
                      ),
                    );
                  },
                ),
              ),

              // Tigelas empilhadas
              Positioned(
                bottom: 0,
                child: Column(
                  children: [
                    // Tigela atual sendo comida
                    if (_currentBowls > 0)
                      Transform.scale(
                        scale: 1.0 - _eatProgress * 0.5,
                        child: _buildBowl(),
                      ),

                    // Tigelas já comidas
                    ...List.generate(
                      _currentBowls - 1,
                      (index) => _buildBowl(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            widget.loadingText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark
                  ? onSurface.withValues(alpha: 0.9)
                  : Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isEating)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Comendo... Toque para acelerar!',
                style: TextStyle(
                  color: isDark
                      ? onSurface.withValues(alpha: 0.7)
                      : Colors.orange[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBowl() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Icon(
      Icons.ramen_dining,
      size: widget.size * 0.3,
      color: isDark ? primaryColor.withValues(alpha: 0.6) : Colors.brown[300],
    );
  }
}
