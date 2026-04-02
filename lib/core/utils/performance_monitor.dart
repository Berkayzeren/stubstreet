// lib/core/utils/performance_monitor.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance monitoring utility for production builds
/// 
/// Bu sınıf production ortamında performans izleme sağlar
/// ve debug modda detaylı loglar tutar.
class PerformanceMonitor {
  static const String _tag = '[PERF]';
  static final Map<String, DateTime> _startTimes = {};
  static final List<String> _operations = [];
  
  /// Start timing an operation
  static void startTimer(String operationName) {
    _startTimes[operationName] = DateTime.now();
    if (kDebugMode) {
      debugPrint('$_tag Started: $operationName');
    }
  }
  
  /// End timing and log performance
  static void endTimer(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime == null) return;
    
    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(operationName);
    
    // Only log slow operations in production
    if (duration.inMilliseconds > 100 || kDebugMode) {
      final message = '$_tag Completed: $operationName (${duration.inMilliseconds}ms)';
      if (kDebugMode) {
        debugPrint(message);
      }
      _operations.add(message);
      
      // Keep only last 50 operations
      if (_operations.length > 50) {
        _operations.removeAt(0);
      }
    }
  }
  
  /// Log memory usage
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      debugPrint('$_tag Memory check at: $context');
    }
  }
  
  /// Get performance report
  static List<String> getReport() {
    return List.from(_operations);
  }
  
  /// Clear performance data
  static void clear() {
    _startTimes.clear();
    _operations.clear();
  }
  
  /// Monitor widget build times
  static T measureBuild<T>(String widgetName, T Function() buildFunction) {
    startTimer('Build:$widgetName');
    final result = buildFunction();
    endTimer('Build:$widgetName');
    return result;
  }
  
  /// Monitor async operations
  static Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    startTimer('Async:$operationName');
    try {
      final result = await operation();
      endTimer('Async:$operationName');
      return result;
    } catch (e) {
      endTimer('Async:$operationName');
      rethrow;
    }
  }
}

/// Mixin for automatic performance monitoring in StatefulWidgets
mixin PerformanceMonitorMixin<T extends StatefulWidget> on State<T> {
  late final String _widgetName = T.toString();
  
  @override
  void initState() {
    PerformanceMonitor.startTimer('Init:$_widgetName');
    super.initState();
    PerformanceMonitor.endTimer('Init:$_widgetName');
  }
  
  @override
  void dispose() {
    PerformanceMonitor.logMemoryUsage('Dispose:$_widgetName');
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return PerformanceMonitor.measureBuild(
      'Build:$_widgetName',
      () => performanceBuild(context),
    );
  }
  
  /// Override this instead of build()
  Widget performanceBuild(BuildContext context);
}

/// Debug-only print replacement
void debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}
