// lib/core/animations/page_transitions.dart

import 'package:flutter/material.dart';
import 'app_animations.dart';

/// Page transition animations
/// 
/// Bu sınıf sayfa geçişleri için özel animasyonları içerir.
/// Modern ve kullanıcı dostu geçiş efektleri sağlar.
class PageTransitions {
  
  /// Slide transition from right - sağdan kayarak giriş
  static PageRouteBuilder slideFromRight<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.normal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Slide transition from left - soldan kayarak giriş
  static PageRouteBuilder slideFromLeft<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.normal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Fade transition - solma efekti
  static PageRouteBuilder fadeTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.normal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Scale transition - büyüme efekti
  static PageRouteBuilder scaleTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.normal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.elasticOut;
        var tween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Custom slide and scale - kayma ve büyüme kombinasyonu
  static PageRouteBuilder slideAndScale<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.normal,
    Offset beginOffset = const Offset(0.0, 1.0),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var slideTween = Tween(begin: beginOffset, end: end).chain(
          CurveTween(curve: curve),
        );
        
        var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(slideTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Bottom sheet transition - alt sayfa geçişi
  static PageRouteBuilder bottomSheetTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.normal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
    );
  }

  /// Dialog transition - dialog geçişi
  static PageRouteBuilder dialogTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.normal,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.elasticOut;
        var scaleTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeIn),
        );

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Shared axis transition - paylaşılan eksen geçişi
  static PageRouteBuilder sharedAxisTransition<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = AppAnimations.normal,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.scaled,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (transitionType) {
          case SharedAxisTransitionType.horizontal:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(-1.0, 0.0),
                ).animate(CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
          
          case SharedAxisTransitionType.vertical:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          
          case SharedAxisTransitionType.scaled:
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
        }
      },
    );
  }
}

/// Shared axis transition types
enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

// Enhanced navigation extensions - temporarily disabled due to generic issues
// extension NavigatorAnimationExtensions on NavigatorState {
//   Future<T?> pushSlideFromRight<T extends Object?>(Widget page) {
//     return push<T>(PageTransitions.slideFromRight<T>(page: page));
//   }
//   
//   Future<T?> pushFade<T extends Object?>(Widget page) {
//     return push<T>(PageTransitions.fadeTransition<T>(page: page));
//   }
//   
//   Future<T?> pushScale<T extends Object?>(Widget page) {
//     return push<T>(PageTransitions.scaleTransition<T>(page: page));
//   }
//   
//   Future<T?> pushBottomSheet<T extends Object?>(Widget page) {
//     return push<T>(PageTransitions.bottomSheetTransition<T>(page: page));
//   }
// }
