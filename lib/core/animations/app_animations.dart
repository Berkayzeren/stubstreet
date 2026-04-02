// lib/core/animations/app_animations.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Uygulama genelinde kullanılan animasyon sistemi
/// 
/// Bu sınıf mantıklı ve kullanıcı deneyimini geliştiren animasyonları
/// merkezi bir şekilde yönetir. Animasyonlar kullanıcı etkileşimlerine
/// anlamlı geri bildirim sağlar.
class AppAnimations {
  // Animation durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration veryFast = Duration(milliseconds: 100);

  // Animation curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve spring = Curves.elasticInOut;

  /// Button press animation - basıldığında küçülme efekti
  static void buttonPressAnimation(TickerProvider vsync, VoidCallback onComplete) {
    final controller = AnimationController(duration: fast, vsync: vsync);
    // Animation setup for button press
    // final animation = Tween<double>(begin: 1.0, end: 0.95).animate(
    //   CurvedAnimation(parent: controller, curve: easeOut),
    // );

    controller.forward().then((_) {
      controller.reverse().then((_) {
        onComplete();
        controller.dispose();
      });
    });
  }

  /// Success pulse animation - başarı durumunda nabız efekti
  static AnimationController createSuccessPulse(TickerProvider vsync) {
    final controller = AnimationController(duration: normal, vsync: vsync);
    return controller;
  }

  /// Shimmer loading animation - yükleme durumunda parıltı efekti
  static AnimationController createShimmerAnimation(TickerProvider vsync) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: vsync,
    );
    controller.repeat();
    return controller;
  }

  /// Slide in animation - içerik girişi için kaydırma
  static Animation<Offset> createSlideInAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, 1),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: easeOut),
    );
  }

  /// Fade animation - solma efekti
  static Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: easeInOut),
    );
  }

  /// Scale animation - büyüme/küçülme efekti
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: controller, curve: bounce),
    );
  }

  /// Rotation animation - döndürme efekti
  static Animation<double> createRotationAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: easeInOut),
    );
  }

  /// Staggered list animation - liste öğeleri için aşamalı animasyon
  static Animation<double> createStaggeredAnimation(
    AnimationController controller,
    int index,
    int totalItems,
  ) {
    final start = index / totalItems * 0.5;
    final end = start + 0.5;
    
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: easeOut),
      ),
    );
  }
}

/// Animasyonlu buton widget'ı
/// 
/// Bu widget buton etkileşimlerine anlamlı animasyonlar ekler.
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double elevation;
  final bool isLoading;
  final Duration animationDuration;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation = 4,
    this.isLoading = false,
    this.animationDuration = AppAnimations.fast,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for press feedback
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Shimmer animation for loading state
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    
    // Start shimmer if loading
    if (widget.isLoading) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle loading state changes
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
        _shimmerController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _scaleController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      _scaleController.reverse();
      setState(() {
        _isPressed = false;
      });
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      _scaleController.reverse();
      setState(() {
        _isPressed = false;
      });
    }
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.mediumImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _shimmerAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? theme.primaryColor,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: widget.elevation,
                    offset: Offset(0, widget.elevation / 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main content
                  DefaultTextStyle(
                    style: TextStyle(
                      color: widget.foregroundColor ?? Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    child: widget.child,
                  ),
                  
                  // Shimmer overlay for loading
                  if (widget.isLoading)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: const [0.0, 0.5, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                              transform: GradientRotation(_shimmerAnimation.value),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Success animation widget
/// 
/// Başarı durumlarında kullanılan animasyonlu widget.
class SuccessAnimation extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final VoidCallback? onComplete;

  const SuccessAnimation({
    super.key,
    required this.child,
    required this.show,
    this.duration = AppAnimations.normal,
    this.onComplete,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    if (widget.show) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(SuccessAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _startAnimation();
      } else {
        _controller.reverse();
      }
    }
  }

  void _startAnimation() {
    HapticFeedback.lightImpact();
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Error shake animation
/// 
/// Hata durumlarında kullanılan titreme animasyonu.
class ErrorShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;

  const ErrorShakeAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<ErrorShakeAnimation> createState() => _ErrorShakeAnimationState();
}

class _ErrorShakeAnimationState extends State<ErrorShakeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(ErrorShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.trigger && !oldWidget.trigger) {
      _startShake();
    }
  }

  void _startShake() {
    HapticFeedback.heavyImpact();
    _controller.forward().then((_) {
      _controller.reset();
    });
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
        // Create shake effect with sine wave
        final shakeValue = _animation.value * 4 * 3.14159; // 4 shakes
        final offset = Offset(math.sin(shakeValue) * 8, 0);
        
        return Transform.translate(
          offset: offset,
          child: widget.child,
        );
      },
    );
  }
}

/// Skeleton loading widget
/// 
/// İçerik yüklenirken gösterilen iskelet animasyonu.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? Colors.grey.shade300;
    final highlightColor = widget.highlightColor ?? Colors.grey.shade100;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              transform: GradientRotation(_animation.value),
            ),
          ),
        );
      },
    );
  }
}

/// Staggered list animation
/// 
/// Liste öğeleri için aşamalı animasyon wrapper'ı.
class StaggeredListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration delay;
  final Axis direction;

  const StaggeredListAnimation({
    super.key,
    required this.children,
    this.duration = AppAnimations.normal,
    this.delay = const Duration(milliseconds: 100),
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredListAnimation> createState() => _StaggeredListAnimationState();
}

class _StaggeredListAnimationState extends State<StaggeredListAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(duration: widget.duration, vsync: this);
    
    _animations = widget.children.asMap().entries.map((entry) {
      final index = entry.key;
      return AppAnimations.createStaggeredAnimation(
        _controller,
        index,
        widget.children.length,
      );
    }).toList();
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final animation = _animations[index];
        
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final slideOffset = widget.direction == Axis.vertical
                ? Offset(0, (1 - animation.value) * 50)
                : Offset((1 - animation.value) * 50, 0);
            
            return Transform.translate(
              offset: slideOffset,
              child: Opacity(
                opacity: animation.value,
                child: child,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
