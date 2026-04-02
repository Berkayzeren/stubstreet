// lib/core/services/user_activity_tracker.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state_manager.dart';
import 'dart:developer' as developer;

/// Provider for AuthStateManager to track user activity
final authStateManagerProvider = Provider<AuthStateManager?>((ref) {
  // This will be set when user logs in
  return null;
});

/// Widget that tracks user activity and records it in AuthStateManager
class UserActivityTracker extends ConsumerWidget {
  final Widget child;
  final AuthStateManager? authStateManager;

  const UserActivityTracker({
    super.key,
    required this.child,
    this.authStateManager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _recordActivity(),
      onPanStart: (_) => _recordActivity(),
      onScaleStart: (_) => _recordActivity(),
      behavior: HitTestBehavior.translucent,
      child: Listener(
        onPointerDown: (_) => _recordActivity(),
        onPointerMove: (_) => _recordActivity(),
        child: child,
      ),
    );
  }

  void _recordActivity() {
    try {
      authStateManager?.recordActivity();
    } catch (e) {
      developer.log(
        'Error recording user activity: $e',
        name: 'UserActivityTracker',
      );
    }
  }
}

/// Mixin to easily add activity tracking to any widget
mixin UserActivityMixin {
  void recordUserActivity(AuthStateManager? authStateManager) {
    try {
      authStateManager?.recordActivity();
    } catch (e) {
      developer.log(
        'Error recording user activity: $e',
        name: 'UserActivityMixin',
      );
    }
  }
}

/// Extension to add activity tracking to navigation
extension NavigationActivityTracking on NavigatorState {
  void recordActivity(AuthStateManager? authStateManager) {
    try {
      authStateManager?.recordActivity();
    } catch (e) {
      developer.log(
        'Error recording navigation activity: $e',
        name: 'NavigationActivityTracking',
      );
    }
  }
}

/// Custom Navigator Observer to track navigation as user activity
class ActivityTrackingNavigatorObserver extends NavigatorObserver {
  final AuthStateManager? authStateManager;

  ActivityTrackingNavigatorObserver(this.authStateManager);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _recordActivity('navigation_push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _recordActivity('navigation_pop');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _recordActivity('navigation_replace');
  }

  void _recordActivity(String action) {
    try {
      authStateManager?.recordActivity();
      developer.log(
        'Navigation activity recorded: $action',
        name: 'ActivityTrackingNavigatorObserver',
      );
    } catch (e) {
      developer.log(
        'Error recording navigation activity: $e',
        name: 'ActivityTrackingNavigatorObserver',
      );
    }
  }
}
