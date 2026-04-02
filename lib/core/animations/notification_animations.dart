// lib/core/animations/notification_animations.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_animations.dart';

/// Notification and alert animations
/// 
/// Bu sınıf bildirimler ve uyarılar için özel animasyonları içerir.
/// Push notification'lar, in-app alert'ler ve banner'lar için optimize edilmiş
/// animasyonlar sağlar.
class NotificationAnimations {
  
  /// Show animated notification banner
  /// 
  /// Üstten aşağı kayarak gelen bildirim banner'ı
  static void showNotificationBanner({
    required BuildContext context,
    required String title,
    String? message,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 4),
    Duration animationDuration = AppAnimations.normal,
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedNotificationBanner(
        title: title,
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        textColor: textColor,
        duration: duration,
        animationDuration: animationDuration,
        onTap: onTap,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
    HapticFeedback.lightImpact();
  }

  /// Show toast notification
  /// 
  /// Altta kayarak çıkan toast bildirim
  static void showToast({
    required BuildContext context,
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = AppAnimations.normal,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedToast(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        duration: duration,
        animationDuration: animationDuration,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
    HapticFeedback.selectionClick();
  }

  /// Show popup notification
  /// 
  /// Ortadan büyüyerek çıkan popup bildirim
  static void showPopupNotification({
    required BuildContext context,
    required Widget content,
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = AppAnimations.normal,
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedPopupNotification(
        content: content,
        duration: duration,
        animationDuration: animationDuration,
        onTap: onTap,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
    HapticFeedback.mediumImpact();
  }

  /// Show floating action notification
  /// 
  /// FAB benzeri floating notification
  static void showFloatingNotification({
    required BuildContext context,
    required Widget content,
    Duration duration = const Duration(seconds: 5),
    Duration animationDuration = AppAnimations.normal,
    Alignment alignment = Alignment.bottomRight,
    EdgeInsets margin = const EdgeInsets.all(16),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedFloatingNotification(
        content: content,
        duration: duration,
        animationDuration: animationDuration,
        alignment: alignment,
        margin: margin,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

/// Animated notification banner widget
class AnimatedNotificationBanner extends StatefulWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration duration;
  final Duration animationDuration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const AnimatedNotificationBanner({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.backgroundColor,
    this.textColor,
    required this.duration,
    required this.animationDuration,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<AnimatedNotificationBanner> createState() => _AnimatedNotificationBannerState();
}

class _AnimatedNotificationBannerState extends State<AnimatedNotificationBanner>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));
    
    _slideController.forward();
    _progressController.forward();
    
    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;
    final textColor = widget.textColor ?? Colors.white;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      widget.onTap?.call();
                      _dismiss();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: textColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                          ],
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.message != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.message!,
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                color: textColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Progress indicator
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: textColor.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated toast widget
class AnimatedToast extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Duration duration;
  final Duration animationDuration;
  final VoidCallback onDismiss;

  const AnimatedToast({
    super.key,
    required this.message,
    this.icon,
    this.backgroundColor,
    required this.duration,
    required this.animationDuration,
    required this.onDismiss,
  });

  @override
  State<AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<AnimatedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    _controller.forward();
    
    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? 
        (theme.brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade900);

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated popup notification widget
class AnimatedPopupNotification extends StatefulWidget {
  final Widget content;
  final Duration duration;
  final Duration animationDuration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const AnimatedPopupNotification({
    super.key,
    required this.content,
    required this.duration,
    required this.animationDuration,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<AnimatedPopupNotification> createState() => _AnimatedPopupNotificationState();
}

class _AnimatedPopupNotificationState extends State<AnimatedPopupNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    _controller.forward();
    
    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: () {
                  widget.onTap?.call();
                  _controller.reverse().then((_) {
                    widget.onDismiss();
                  });
                },
                child: widget.content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated floating notification widget
class AnimatedFloatingNotification extends StatefulWidget {
  final Widget content;
  final Duration duration;
  final Duration animationDuration;
  final Alignment alignment;
  final EdgeInsets margin;
  final VoidCallback onDismiss;

  const AnimatedFloatingNotification({
    super.key,
    required this.content,
    required this.duration,
    required this.animationDuration,
    required this.alignment,
    required this.margin,
    required this.onDismiss,
  });

  @override
  State<AnimatedFloatingNotification> createState() => _AnimatedFloatingNotificationState();
}

class _AnimatedFloatingNotificationState extends State<AnimatedFloatingNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Determine slide direction based on alignment
    Offset beginOffset;
    if (widget.alignment == Alignment.bottomRight || widget.alignment == Alignment.centerRight) {
      beginOffset = const Offset(1.0, 0.0);
    } else if (widget.alignment == Alignment.bottomLeft || widget.alignment == Alignment.centerLeft) {
      beginOffset = const Offset(-1.0, 0.0);
    } else if (widget.alignment == Alignment.topCenter || widget.alignment == Alignment.topLeft || widget.alignment == Alignment.topRight) {
      beginOffset = const Offset(0.0, -1.0);
    } else {
      beginOffset = const Offset(0.0, 1.0);
    }
    
    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
    
    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: widget.alignment,
        child: Container(
          margin: widget.margin,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.content,
            ),
          ),
        ),
      ),
    );
  }
}
