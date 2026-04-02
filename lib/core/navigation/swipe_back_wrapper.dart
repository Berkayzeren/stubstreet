// lib/core/navigation/swipe_back_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global kaydırma ile geri gitme özelliği wrapper'ı
/// 
/// Bu widget tüm sayfalarda soldan sağa kaydırma hareketiyle
/// geri gitme özelliği sağlar. Kullanım:
/// - Ekranın sol kenarından sağa doğru kaydırın
/// - Minimum %30 kaydırma ile geri gitme tetiklenir
/// - Haptic feedback ile kullanıcı geri bildirimi
/// - Smooth animation ile sayfa geçişi
class SwipeBackWrapper extends StatefulWidget {
  final Widget child;
  final bool enableSwipeBack;
  final double swipeThreshold;
  final Duration animationDuration;
  final VoidCallback? onSwipeStart;
  final VoidCallback? onSwipeCancel;
  final VoidCallback? onSwipeComplete;

  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.enableSwipeBack = true,
    this.swipeThreshold = 0.3, // 30% of screen width
    this.animationDuration = const Duration(milliseconds: 300),
    this.onSwipeStart,
    this.onSwipeCancel,
    this.onSwipeComplete,
  });

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper>
    with TickerProviderStateMixin {
  
  // Animation controllers for smooth transitions
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  // Animations for visual feedback
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  // Gesture tracking variables
  bool _isSwipeInProgress = false;
  double _swipeProgress = 0.0;
  double _startX = 0.0;
  
  // Screen dimensions
  double _screenWidth = 0.0;
  
  // Edge detection zone (in pixels from left edge)
  static const double _edgeWidth = 20.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Initialize all animations for smooth swipe-back effect
  void _initializeAnimations() {
    // Slide animation - moves the current page to the right
    _slideController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Scale animation - slightly scales down the page during swipe
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Configure slide animation (0 to 1 = left to right movement)
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Configure scale animation (slight zoom out effect)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    // Configure opacity animation (fade effect)
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  /// Handle the start of a pan gesture
  void _onPanStart(DragStartDetails details) {
    if (!widget.enableSwipeBack) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    _screenWidth = screenWidth;
    
    // Only start swipe if gesture begins near the left edge
    if (details.globalPosition.dx <= _edgeWidth) {
      _startX = details.globalPosition.dx;
      _isSwipeInProgress = true;
      
      // Provide haptic feedback to indicate swipe start
      HapticFeedback.lightImpact();
      
      // Notify callback
      widget.onSwipeStart?.call();
      
      debugPrint('🚀 Swipe back started at position: ${details.globalPosition.dx}');
    }
  }

  /// Handle pan gesture updates
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isSwipeInProgress || !widget.enableSwipeBack) return;
    
    final currentX = details.globalPosition.dx;
    final deltaX = currentX - _startX;
    
    // Only allow rightward swipes (positive delta)
    if (deltaX > 0) {
      // Calculate swipe progress (0.0 to 1.0)
      _swipeProgress = (deltaX / _screenWidth).clamp(0.0, 1.0);
      
      // Update animation controllers based on swipe progress
      _slideController.value = _swipeProgress;
      _scaleController.value = _swipeProgress;
      
      // Provide progressive haptic feedback
      if (_swipeProgress > 0.1 && _swipeProgress < 0.12) {
        HapticFeedback.selectionClick();
      }
      
      debugPrint('📏 Swipe progress: ${(_swipeProgress * 100).toStringAsFixed(1)}%');
    }
  }

  /// Handle the end of a pan gesture
  void _onPanEnd(DragEndDetails details) {
    if (!_isSwipeInProgress || !widget.enableSwipeBack) return;
    
    _isSwipeInProgress = false;
    
    // Determine if swipe should trigger navigation
    final shouldNavigateBack = _swipeProgress >= widget.swipeThreshold;
    
    if (shouldNavigateBack) {
      _completeSwipeBack();
    } else {
      _cancelSwipeBack();
    }
  }

  /// Complete the swipe-back navigation
  void _completeSwipeBack() {
    // Animate to completion
    _slideController.forward().then((_) {
      // Navigate back after animation completes
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Reset animations
      _resetAnimations();
      
      // Provide success haptic feedback
      HapticFeedback.mediumImpact();
      
      // Notify callback
      widget.onSwipeComplete?.call();
      
      debugPrint('✅ Swipe back completed - navigating to previous page');
    });
    
    _scaleController.forward();
  }

  /// Cancel the swipe-back gesture
  void _cancelSwipeBack() {
    // Animate back to original position
    _slideController.reverse();
    _scaleController.reverse();
    
    // Provide cancel haptic feedback
    HapticFeedback.lightImpact();
    
    // Notify callback
    widget.onSwipeCancel?.call();
    
    debugPrint('❌ Swipe back cancelled - returning to original position');
  }

  /// Reset all animations to initial state
  void _resetAnimations() {
    _slideController.reset();
    _scaleController.reset();
    _swipeProgress = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableSwipeBack) {
      return widget.child;
    }

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_slideController, _scaleController]),
        builder: (context, child) {
          return Stack(
            children: [
              // Background shadow effect
              if (_swipeProgress > 0)
                Container(
                  color: Colors.black.withValues(
                    alpha: 0.1 * _swipeProgress,
                  ),
                ),
              
              // Main content with transform effects
              Transform.translate(
                offset: Offset(_slideAnimation.value.dx * _screenWidth, 0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: widget.child,
                  ),
                ),
              ),
              
              // Swipe progress indicator
              if (_swipeProgress > 0.1)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 20,
                  child: _buildSwipeIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Build swipe progress indicator
  Widget _buildSwipeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Geri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _swipeProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: _swipeProgress >= widget.swipeThreshold 
                      ? Colors.green 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension to easily wrap any widget with swipe-back functionality
extension SwipeBackExtension on Widget {
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
    return SwipeBackWrapper(
      enableSwipeBack: enableSwipeBack,
      swipeThreshold: swipeThreshold,
      animationDuration: animationDuration,
      onSwipeStart: onSwipeStart,
      onSwipeCancel: onSwipeCancel,
      onSwipeComplete: onSwipeComplete,
      child: this,
    );
  }
}
