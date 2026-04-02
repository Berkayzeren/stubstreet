// lib/core/navigation/custom_page_route.dart

import 'package:flutter/material.dart';
import 'swipe_back_wrapper.dart';

/// Özel sayfa geçişi sınıfı - tüm sayfalar için swipe-back özelliği
/// 
/// Bu sınıf MaterialPageRoute'u extend ederek tüm sayfa geçişlerine
/// otomatik olarak swipe-back özelliği ekler.
class CustomPageRoute<T> extends MaterialPageRoute<T> {
  final bool enableSwipeBack;
  final double swipeThreshold;

  CustomPageRoute({
    required super.builder,
    super.settings,
    super.maintainState = true,
    super.fullscreenDialog = false,
    this.enableSwipeBack = true,
    this.swipeThreshold = 0.3,
  });

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // Build the original page
    final page = super.buildPage(context, animation, secondaryAnimation);
    
    // Wrap with swipe-back functionality if enabled
    if (enableSwipeBack && !fullscreenDialog) {
      return SwipeBackWrapper(
        enableSwipeBack: enableSwipeBack,
        swipeThreshold: swipeThreshold,
        child: page,
      );
    }
    
    return page;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use slide transition for smooth page changes
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0), // Start from right
        end: Offset.zero, // End at current position
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0), // Previous page slides slightly left
        ).animate(CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

/// Custom page transitions theme for consistent swipe-back across all platforms
/// 
/// Bu sınıf tüm platform'larda (Android, iOS, Web) tutarlı
/// swipe-back davranışı sağlar.
class CustomPageTransitionsTheme extends PageTransitionsTheme {
  const CustomPageTransitionsTheme();

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Apply custom transitions to all platforms
    // Wrap with swipe-back if not already handled by CustomPageRoute
    Widget effectiveChild = child;
    final bool canSwipe = Navigator.of(context).canPop();
    if (route is! CustomPageRoute && canSwipe && !route.fullscreenDialog) {
      effectiveChild = SwipeBackWrapper(
        enableSwipeBack: true,
        swipeThreshold: 0.3,
        child: effectiveChild,
      );
    }

    return _CustomPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      child: effectiveChild,
    );
  }
}

/// Internal custom page transition widget
/// 
/// Bu widget sayfa geçişlerinde kullanılan animasyonları yönetir.
class _CustomPageTransition extends StatelessWidget {
  final Animation<double> primaryRouteAnimation;
  final Animation<double> secondaryRouteAnimation;
  final Widget child;

  const _CustomPageTransition({
    required this.primaryRouteAnimation,
    required this.secondaryRouteAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: primaryRouteAnimation,
        curve: Curves.easeOutCubic,
      )),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).animate(CurvedAnimation(
          parent: secondaryRouteAnimation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

/// Navigation helpers for easy page navigation with swipe-back
/// 
/// Bu sınıf kolay navigasyon metodları sağlar.
class NavigationHelper {
  /// Navigate to a new page with swipe-back enabled
  /// 
  /// @param context - Build context
  /// @param builder - Widget builder function
  /// @param enableSwipeBack - Enable/disable swipe back (default: true)
  /// @param swipeThreshold - Swipe threshold percentage (default: 0.3)
  /// @param settings - Route settings
  static Future<T?> pushWithSwipeBack<T extends Object?>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      CustomPageRoute<T>(
        builder: builder,
        enableSwipeBack: enableSwipeBack,
        swipeThreshold: swipeThreshold,
        settings: settings,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  /// Replace current page with a new page (with swipe-back)
  /// 
  /// @param context - Build context  
  /// @param builder - Widget builder function
  /// @param enableSwipeBack - Enable/disable swipe back (default: true)
  static Future<T?> pushReplacementWithSwipeBack<T extends Object?, TO extends Object?>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
    RouteSettings? settings,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      CustomPageRoute<T>(
        builder: builder,
        enableSwipeBack: enableSwipeBack,
        swipeThreshold: swipeThreshold,
        settings: settings,
      ),
      result: result,
    );
  }

  /// Push and remove all previous routes
  /// 
  /// @param context - Build context
  /// @param builder - Widget builder function
  /// @param enableSwipeBack - Enable/disable swipe back (default: true)
  static Future<T?> pushAndRemoveUntilWithSwipeBack<T extends Object?>(
    BuildContext context, {
    required WidgetBuilder builder,
    required RoutePredicate predicate,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
    RouteSettings? settings,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      CustomPageRoute<T>(
        builder: builder,
        enableSwipeBack: enableSwipeBack,
        swipeThreshold: swipeThreshold,
        settings: settings,
      ),
      predicate,
    );
  }
}

