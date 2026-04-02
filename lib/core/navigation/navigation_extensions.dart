// lib/core/navigation/navigation_extensions.dart

import 'package:flutter/material.dart';
import 'custom_page_route.dart';

/// Global extension methods for easy swipe-back navigation
/// 
/// Bu extension'lar mevcut Navigator.push çağrılarını
/// otomatik olarak swipe-back destekli hale getirir.
extension SwipeNavigationExtensions on NavigatorState {
  /// Push a page with automatic swipe-back support
  /// 
  /// Mevcut Navigator.push çağrılarını değiştirmeden
  /// swipe-back özelliği ekler.
  Future<T?> pushWithSwipeBack<T extends Object?>(
    Widget Function(BuildContext) builder, {
    RouteSettings? settings,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return push<T>(
      CustomPageRoute<T>(
        builder: builder,
        settings: settings,
        enableSwipeBack: enableSwipeBack,
        swipeThreshold: swipeThreshold,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
      ),
    );
  }

  /// Push replacement with swipe-back support
  Future<T?> pushReplacementWithSwipeBack<T extends Object?, TO extends Object?>(
    Widget Function(BuildContext) builder, {
    RouteSettings? settings,
    TO? result,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
  }) {
    return pushReplacement<T, TO>(
      CustomPageRoute<T>(
        builder: builder,
        settings: settings,
        enableSwipeBack: enableSwipeBack,
        swipeThreshold: swipeThreshold,
      ),
      result: result,
    );
  }

  /// Push and remove until with swipe-back support
  Future<T?> pushAndRemoveUntilWithSwipeBack<T extends Object?>(
    Widget Function(BuildContext) builder,
    bool Function(Route<dynamic>) predicate, {
    RouteSettings? settings,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
  }) {
    return pushAndRemoveUntil<T>(
      CustomPageRoute<T>(
        builder: builder,
        settings: settings,
        enableSwipeBack: enableSwipeBack,
        swipeThreshold: swipeThreshold,
      ),
      predicate,
    );
  }
}

/// Context extension for even easier navigation
/// 
/// Bu extension sayesinde context.pushSwipeBack() şeklinde
/// kolayca navigation yapılabilir.
extension SwipeNavigationContext on BuildContext {
  /// Navigate to a new page with swipe-back
  /// 
  /// Usage:
  /// ```dart
  /// context.pushSwipeBack((context) => MyNewPage());
  /// ```
  Future<T?> pushSwipeBack<T extends Object?>(
    Widget Function(BuildContext) builder, {
    RouteSettings? settings,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(this).pushWithSwipeBack<T>(
      builder,
      settings: settings,
      enableSwipeBack: enableSwipeBack,
      swipeThreshold: swipeThreshold,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Replace current page with swipe-back
  Future<T?> pushReplacementSwipeBack<T extends Object?, TO extends Object?>(
    Widget Function(BuildContext) builder, {
    RouteSettings? settings,
    TO? result,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
  }) {
    return Navigator.of(this).pushReplacementWithSwipeBack<T, TO>(
      builder,
      settings: settings,
      result: result,
      enableSwipeBack: enableSwipeBack,
      swipeThreshold: swipeThreshold,
    );
  }

  /// Push and clear stack with swipe-back
  Future<T?> pushAndClearStackSwipeBack<T extends Object?>(
    Widget Function(BuildContext) builder, {
    RouteSettings? settings,
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
  }) {
    return Navigator.of(this).pushAndRemoveUntilWithSwipeBack<T>(
      builder,
      (route) => false,
      settings: settings,
      enableSwipeBack: enableSwipeBack,
      swipeThreshold: swipeThreshold,
    );
  }

  /// Navigate to a named route (still uses regular navigation)
  /// 
  /// Named route'lar için swipe-back özelliği PageTransitionsTheme
  /// aracılığıyla otomatik olarak eklenir.
  Future<T?> pushNamedSwipeBack<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Check if we can swipe back
  bool get canSwipeBack {
    return Navigator.of(this).canPop();
  }
}

/// Widget extension for wrapping with swipe-back
/// 
/// Bu extension herhangi bir widget'ı swipe-back özelliği ile
/// wrap etmek için kullanılır.
extension SwipeBackWidget on Widget {
  /// Wrap this widget with swipe-back functionality
  /// 
  /// Usage:
  /// ```dart
  /// MyWidget().withSwipeBack()
  /// ```
  Widget withSwipeBack({
    bool enableSwipeBack = true,
    double swipeThreshold = 0.3,
    Duration animationDuration = const Duration(milliseconds: 300),
    VoidCallback? onSwipeStart,
    VoidCallback? onSwipeCancel,
    VoidCallback? onSwipeComplete,
  }) {
    return Builder(
      builder: (context) {
        // Import the SwipeBackWrapper here to avoid circular dependencies
        return Container(
          child: this, // Will be replaced with actual SwipeBackWrapper in implementation
        );
      },
    );
  }
}

/// Utility class for navigation helpers
/// 
/// Bu sınıf yaygın navigation pattern'leri için
/// helper metotlar sağlar.
class SwipeNavigationUtils {
  /// Navigate to login screen and clear all previous routes
  static Future<void> navigateToLogin(BuildContext context) {
    return context.pushAndClearStackSwipeBack(
      (context) => Container(), // Will be replaced with actual LoginScreen
      settings: const RouteSettings(name: '/login'),
    );
  }

  /// Navigate to home screen and clear all previous routes
  static Future<void> navigateToHome(BuildContext context, {int? tabIndex}) {
    return context.pushAndClearStackSwipeBack(
      (context) => Container(), // Will be replaced with actual HomeScreen
      settings: RouteSettings(
        name: '/home',
        arguments: {'tabIndex': tabIndex},
      ),
    );
  }

  /// Navigate back with animation
  static void goBack(BuildContext context, {Object? result}) {
    if (context.canSwipeBack) {
      Navigator.of(context).pop(result);
    }
  }

  /// Check if a specific route is in the navigation stack
  static bool isRouteInStack(BuildContext context, String routeName) {
    bool routeExists = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == routeName) {
        routeExists = true;
      }
      return true; // Don't actually pop, just check
    });
    return routeExists;
  }

  /// Get current route name
  static String? getCurrentRouteName(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  /// Navigate with custom swipe settings for specific use cases
  static Future<T?> navigateWithCustomSwipe<T extends Object?>(
    BuildContext context,
    Widget Function(BuildContext) builder, {
    double swipeThreshold = 0.2, // Easier swipe for specific screens
    bool enableSwipeBack = true,
    RouteSettings? settings,
  }) {
    return context.pushSwipeBack<T>(
      builder,
      swipeThreshold: swipeThreshold,
      enableSwipeBack: enableSwipeBack,
      settings: settings,
    );
  }
}
