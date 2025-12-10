import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class CustomPageTransitions {
  // Slide from right animation
  static PageRouteBuilder slideRight(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.rightToLeft,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
  }

  // Fade in animation
  static PageRouteBuilder fadeIn(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.fade,
      duration: const Duration(milliseconds: 400),
    );
  }

  // Scale animation
  static PageRouteBuilder scale(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.scale,
      alignment: Alignment.center,
      duration: const Duration(milliseconds: 400),
    );
  }

  // Slide from bottom animation
  static PageRouteBuilder slideUp(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.bottomToTop,
      duration: const Duration(milliseconds: 350),
    );
  }

  // Rotate animation
  static PageRouteBuilder rotate(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.rotate,
      alignment: Alignment.center,
      duration: const Duration(milliseconds: 500),
    );
  }

  // Size animation
  static PageRouteBuilder size(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.size,
      alignment: Alignment.center,
      duration: const Duration(milliseconds: 400),
    );
  }
}

// Easy-to-use extension for Navigator
extension CustomNavigator on BuildContext {
  // Slide right transition
  Future<T?> slideRightTo<T>(Widget page) {
    return Navigator.push<T>(
      this,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  // Fade transition
  Future<T?> fadeTo<T>(Widget page) {
    return Navigator.push<T>(
      this,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // Scale transition
  Future<T?> scaleTo<T>(Widget page) {
    return Navigator.push<T>(
      this,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
            ),
            child: child,
          );
        },
      ),
    );
  }

  // Slide up transition
  Future<T?> slideUpTo<T>(Widget page) {
    return Navigator.push<T>(
      this,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}
