// lib/core/navigation/route_observer.dart

import 'package:flutter/material.dart';

/// Global route observer for tracking navigation events
/// 
/// Bu sınıf navigation event'lerini takip eder ve 
/// swipe-back özelliği için gerekli context'i sağlar.
class SwipeBackRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  // Singleton instance
  static final SwipeBackRouteObserver _instance = SwipeBackRouteObserver._internal();
  factory SwipeBackRouteObserver() => _instance;
  SwipeBackRouteObserver._internal();

  // Track current route stack
  final List<Route<dynamic>> _routeStack = [];
  
  // Callbacks for route changes
  final List<VoidCallback> _onRouteChangeListeners = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    _routeStack.add(route);
    _notifyRouteChange();
    
    debugPrint('📱 Route pushed: ${route.settings.name ?? route.runtimeType}');
    debugPrint('📚 Current stack depth: ${_routeStack.length}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    
    _routeStack.remove(route);
    _notifyRouteChange();
    
    debugPrint('📱 Route popped: ${route.settings.name ?? route.runtimeType}');
    debugPrint('📚 Current stack depth: ${_routeStack.length}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    
    if (oldRoute != null) {
      _routeStack.remove(oldRoute);
    }
    if (newRoute != null) {
      _routeStack.add(newRoute);
    }
    _notifyRouteChange();
    
    debugPrint('📱 Route replaced: ${oldRoute?.settings.name} → ${newRoute?.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    
    _routeStack.remove(route);
    _notifyRouteChange();
    
    debugPrint('📱 Route removed: ${route.settings.name ?? route.runtimeType}');
  }

  /// Check if swipe back should be enabled for current route
  bool get canSwipeBack {
    return _routeStack.length > 1;
  }

  /// Get current route name
  String? get currentRouteName {
    if (_routeStack.isEmpty) return null;
    return _routeStack.last.settings.name;
  }

  /// Get route stack depth
  int get stackDepth => _routeStack.length;

  /// Add listener for route changes
  void addRouteChangeListener(VoidCallback listener) {
    _onRouteChangeListeners.add(listener);
  }

  /// Remove route change listener
  void removeRouteChangeListener(VoidCallback listener) {
    _onRouteChangeListeners.remove(listener);
  }

  /// Notify all listeners about route changes
  void _notifyRouteChange() {
    for (final listener in _onRouteChangeListeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('Error in route change listener: $e');
      }
    }
  }

  /// Clear all routes (useful for logout scenarios)
  void clearRoutes() {
    _routeStack.clear();
    _notifyRouteChange();
    debugPrint('📱 Route stack cleared');
  }
}
