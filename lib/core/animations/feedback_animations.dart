// lib/core/animations/feedback_animations.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'app_animations.dart';

/// User feedback animations
/// 
/// Bu sınıf kullanıcı geri bildirimlerine yönelik animasyonları içerir.
/// Başarı, hata, uyarı ve bilgilendirme durumları için görsel efektler sağlar.
class FeedbackAnimations {
  
  /// Success snackbar with animation
  /// 
  /// Başarı mesajları için animasyonlu snackbar.
  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AnimatedSuccessMessage(message: message),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: onAction != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// Error snackbar with shake animation
  /// 
  /// Hata mesajları için titremeli snackbar.
  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    HapticFeedback.heavyImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AnimatedErrorMessage(message: message),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'TEKRAR DENE',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Loading overlay with animation
  /// 
  /// İşlem sırasında gösterilen loading overlay.
  static OverlayEntry showLoadingOverlay({
    required BuildContext context,
    String message = 'Yükleniyor...',
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => AnimatedLoadingOverlay(message: message),
    );
    
    overlay.insert(overlayEntry);
    return overlayEntry;
  }

  /// Form validation error animation
  /// 
  /// Form alanları için doğrulama hatası animasyonu.
  static Widget formErrorAnimation({
    required Widget child,
    required bool hasError,
    String? errorMessage,
  }) {
    return FormErrorAnimationWrapper(
      hasError: hasError,
      errorMessage: errorMessage,
      child: child,
    );
  }

  /// Button press feedback animation
  /// 
  /// Buton basma geri bildirimi için animasyon.
  static void buttonPressFeedback({
    Duration duration = AppAnimations.fast,
    bool withHaptic = true,
  }) {
    if (withHaptic) {
      HapticFeedback.lightImpact();
    }
  }

  /// Connection status animation
  /// 
  /// Bağlantı durumu için animasyonlu gösterge.
  static Widget connectionStatusAnimation({
    required bool isConnected,
    String connectedText = 'Bağlı',
    String disconnectedText = 'Bağlantı Yok',
  }) {
    return AnimatedConnectionStatus(
      isConnected: isConnected,
      connectedText: connectedText,
      disconnectedText: disconnectedText,
    );
  }

  /// Data refresh animation
  /// 
  /// Veri yenileme işlemi için animasyon.
  static Widget refreshAnimation({
    required bool isRefreshing,
    required Widget child,
  }) {
    return RefreshAnimationWrapper(
      isRefreshing: isRefreshing,
      child: child,
    );
  }

  /// Achievement unlock animation
  /// 
  /// Başarı kilidi açma animasyonu.
  static void showAchievementUnlock({
    required BuildContext context,
    required String title,
    required String description,
    IconData icon = Icons.stars,
  }) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AchievementUnlockDialog(
        title: title,
        description: description,
        icon: icon,
      ),
    );
  }
}

/// Animated success message widget
class AnimatedSuccessMessage extends StatefulWidget {
  final String message;

  const AnimatedSuccessMessage({
    super.key,
    required this.message,
  });

  @override
  State<AnimatedSuccessMessage> createState() => _AnimatedSuccessMessageState();
}

class _AnimatedSuccessMessageState extends State<AnimatedSuccessMessage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
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
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated error message widget
class AnimatedErrorMessage extends StatefulWidget {
  final String message;

  const AnimatedErrorMessage({
    super.key,
    required this.message,
  });

  @override
  State<AnimatedErrorMessage> createState() => _AnimatedErrorMessageState();
}

class _AnimatedErrorMessageState extends State<AnimatedErrorMessage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shakeValue = _shakeAnimation.value * 4 * 3.14159;
        final offset = Offset(math.sin(shakeValue) * 4, 0);
        
        return Transform.translate(
          offset: offset,
          child: Row(
            children: [
              const Icon(
                Icons.error,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Loading overlay widget
class AnimatedLoadingOverlay extends StatefulWidget {
  final String message;

  const AnimatedLoadingOverlay({
    super.key,
    required this.message,
  });

  @override
  State<AnimatedLoadingOverlay> createState() => _AnimatedLoadingOverlayState();
}

class _AnimatedLoadingOverlayState extends State<AnimatedLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Form error animation wrapper
class FormErrorAnimationWrapper extends StatefulWidget {
  final Widget child;
  final bool hasError;
  final String? errorMessage;

  const FormErrorAnimationWrapper({
    super.key,
    required this.child,
    required this.hasError,
    this.errorMessage,
  });

  @override
  State<FormErrorAnimationWrapper> createState() => _FormErrorAnimationWrapperState();
}

class _FormErrorAnimationWrapperState extends State<FormErrorAnimationWrapper>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.red.withValues(alpha: 0.1),
    ).animate(_controller);
  }

  @override
  void didUpdateWidget(FormErrorAnimationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.hasError && !oldWidget.hasError) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
      HapticFeedback.lightImpact();
    }
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
        final shakeValue = _shakeAnimation.value * 2 * 3.14159;
        final offset = Offset(math.sin(shakeValue) * 3, 0);
        
        return Transform.translate(
          offset: widget.hasError ? offset : Offset.zero,
          child: Container(
            decoration: BoxDecoration(
              color: widget.hasError ? _colorAnimation.value : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.child,
                if (widget.hasError && widget.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Connection status animation widget
class AnimatedConnectionStatus extends StatefulWidget {
  final bool isConnected;
  final String connectedText;
  final String disconnectedText;

  const AnimatedConnectionStatus({
    super.key,
    required this.isConnected,
    required this.connectedText,
    required this.disconnectedText,
  });

  @override
  State<AnimatedConnectionStatus> createState() => _AnimatedConnectionStatusState();
}

class _AnimatedConnectionStatusState extends State<AnimatedConnectionStatus>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (!widget.isConnected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedConnectionStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _controller.stop();
        _controller.reset();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isConnected ? 1.0 : _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isConnected ? widget.connectedText : widget.disconnectedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Refresh animation wrapper
class RefreshAnimationWrapper extends StatefulWidget {
  final bool isRefreshing;
  final Widget child;

  const RefreshAnimationWrapper({
    super.key,
    required this.isRefreshing,
    required this.child,
  });

  @override
  State<RefreshAnimationWrapper> createState() => _RefreshAnimationWrapperState();
}

class _RefreshAnimationWrapperState extends State<RefreshAnimationWrapper>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    if (widget.isRefreshing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RefreshAnimationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRefreshing != oldWidget.isRefreshing) {
      if (widget.isRefreshing) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: widget.isRefreshing ? _rotationAnimation.value * 2 * math.pi : 0,
          child: widget.child,
        );
      },
    );
  }
}

/// Achievement unlock dialog
class AchievementUnlockDialog extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;

  const AchievementUnlockDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  State<AchievementUnlockDialog> createState() => _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
    
    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
