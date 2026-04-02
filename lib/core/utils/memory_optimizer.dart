// lib/core/utils/memory_optimizer.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Memory optimization utilities
/// 
/// Bu sınıf bellek kullanımını optimize etmek için
/// Stream, Timer ve Controller yönetimi sağlar.
class MemoryOptimizer {
  static final Map<String, List<StreamSubscription>> _subscriptions = {};
  static final Map<String, List<Timer>> _timers = {};
  static final Map<String, List<dynamic>> _controllers = {};

  /// Register a stream subscription for automatic cleanup
  static void registerSubscription(String ownerId, StreamSubscription subscription) {
    _subscriptions.putIfAbsent(ownerId, () => []).add(subscription);
  }

  /// Register a timer for automatic cleanup
  static void registerTimer(String ownerId, Timer timer) {
    _timers.putIfAbsent(ownerId, () => []).add(timer);
  }

  /// Register a controller for automatic cleanup
  static void registerController(String ownerId, dynamic controller) {
    _controllers.putIfAbsent(ownerId, () => []).add(controller);
  }

  /// Clean up all resources for an owner
  static void cleanupOwner(String ownerId) {
    // Cancel subscriptions
    _subscriptions[ownerId]?.forEach((subscription) {
      subscription.cancel();
    });
    _subscriptions.remove(ownerId);

    // Cancel timers
    _timers[ownerId]?.forEach((timer) {
      timer.cancel();
    });
    _timers.remove(ownerId);

    // Dispose controllers
    _controllers[ownerId]?.forEach((controller) {
      try {
        if (controller is StreamController) {
          controller.close();
        } else if (controller.toString().contains('Controller')) {
          // Try to call dispose method if exists
          controller?.dispose();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Warning: Failed to dispose controller: $e');
        }
      }
    });
    _controllers.remove(ownerId);

    if (kDebugMode) {
      debugPrint('🧹 Memory cleanup completed for: $ownerId');
    }
  }

  /// Get memory usage stats
  static Map<String, dynamic> getStats() {
    return {
      'active_subscriptions': _subscriptions.length,
      'active_timers': _timers.length,
      'active_controllers': _controllers.length,
      'owners': _subscriptions.keys.toList(),
    };
  }

  /// Force cleanup all resources (emergency)
  static void emergencyCleanup() {
    final owners = [..._subscriptions.keys, ..._timers.keys, ..._controllers.keys];
    for (final owner in owners) {
      cleanupOwner(owner);
    }
    
    if (kDebugMode) {
      debugPrint('🚨 Emergency memory cleanup completed');
    }
  }
}

/// Mixin for automatic memory management in StatefulWidgets
mixin MemoryOptimizedMixin<T extends StatefulWidget> on State<T> {
  late final String _ownerId = '${T.toString()}_$hashCode';

  /// Register a stream subscription for auto cleanup
  void registerSubscription(StreamSubscription subscription) {
    MemoryOptimizer.registerSubscription(_ownerId, subscription);
  }

  /// Register a timer for auto cleanup
  void registerTimer(Timer timer) {
    MemoryOptimizer.registerTimer(_ownerId, timer);
  }

  /// Register a controller for auto cleanup
  void registerController(dynamic controller) {
    MemoryOptimizer.registerController(_ownerId, controller);
  }

  @override
  void dispose() {
    MemoryOptimizer.cleanupOwner(_ownerId);
    super.dispose();
  }
}

/// Extension for StreamSubscription
extension StreamSubscriptionX on StreamSubscription {
  /// Auto-register for cleanup
  StreamSubscription autoCleanup(State state) {
    if (state is MemoryOptimizedMixin) {
      state.registerSubscription(this);
    }
    return this;
  }
}

/// Extension for Timer
extension TimerX on Timer {
  /// Auto-register for cleanup
  Timer autoCleanup(State state) {
    if (state is MemoryOptimizedMixin) {
      state.registerTimer(this);
    }
    return this;
  }
}
