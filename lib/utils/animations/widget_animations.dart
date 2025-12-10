import 'package:flutter/material.dart';

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
  });

  @override
  FadeInAnimationState createState() => FadeInAnimationState();
}

class FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Add a delay before starting the animation
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;
  final Offset endOffset;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutQuart,
    this.beginOffset = const Offset(0, 0.1),
    this.endOffset = Offset.zero,
  });

  @override
  SlideInAnimationState createState() => SlideInAnimationState();
}

class SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _offsetAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: widget.endOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Add a delay before starting the animation
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offsetAnimation, child: widget.child);
  }
}

class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double begin;
  final double end;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOutBack,
    this.begin = 0.5,
    this.end = 1.0,
  });

  @override
  ScaleAnimationState createState() => ScaleAnimationState();
}

class ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Add a delay before starting the animation
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

class StaggeredListAnimation extends StatefulWidget {
  final int index;
  final int itemCount;
  final Widget child;
  final Duration duration;
  final Curve curve;

  const StaggeredListAnimation({
    super.key,
    required this.index,
    required this.itemCount,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutQuart,
  });

  @override
  StaggeredListAnimationState createState() => StaggeredListAnimationState();
}

class StaggeredListAnimationState extends State<StaggeredListAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      duration: widget.duration,
      delay: Duration(milliseconds: 100 * (widget.index % 5)),
      child: SlideInAnimation(
        duration: widget.duration,
        delay: Duration(milliseconds: 100 * (widget.index % 5)),
        beginOffset: const Offset(0, 0.2),
        child: widget.child,
      ),
    );
  }
}

class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeDistance;
  final int repeatCount;
  final bool infinite;

  const ShakeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 50),
    this.shakeDistance = 10.0,
    this.repeatCount = 3,
    this.infinite = false,
  });

  @override
  ShakeAnimationState createState() => ShakeAnimationState();
}

class ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed &&
            _controller.status != AnimationStatus.completed) {
          if (widget.infinite || _controller.value < widget.repeatCount - 1) {
            _controller.forward();
          }
        }
      });

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            widget.shakeDistance *
                _animation.value *
                (_animation.value > 0.5 ? 1 : -1),
            0.0,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
