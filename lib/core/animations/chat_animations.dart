// lib/core/animations/chat_animations.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_animations.dart';

/// Chat-specific animations
/// 
/// Bu sınıf chat sistemine özel animasyonları içerir.
/// Mesaj gönderme, durum güncellemeleri ve real-time etkileşimler
/// için optimize edilmiş animasyonlar sağlar.
class ChatAnimations {
  
  /// Message send animation - mesaj gönderme animasyonu
  /// 
  /// Bu animasyon mesaj gönderilirken smooth bir geçiş sağlar.
  static Widget animatedMessageSend({
    required Widget child,
    required bool isLoading,
    Duration duration = AppAnimations.fast,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.8),
                ),
              ),
            )
          : child,
    );
  }

  /// Message status animation - mesaj durum animasyonu
  /// 
  /// Mesaj durumu değiştiğinde (sent, delivered, read) gösterilen animasyon.
  static Widget animatedMessageStatus({
    required Widget child,
    required String status,
    Duration duration = AppAnimations.normal,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        // Status'a göre farklı animasyon efektleri
        switch (status) {
          case 'sent':
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.5, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          case 'delivered':
            return ScaleTransition(
              scale: Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              )),
              child: child,
            );
          case 'read':
            return RotationTransition(
              turns: Tween<double>(
                begin: 0.0,
                end: 0.25,
              ).animate(animation),
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          default:
            return FadeTransition(opacity: animation, child: child);
        }
      },
      child: Container(
        key: ValueKey(status),
        child: child,
      ),
    );
  }

  /// Typing indicator animation - yazma göstergesi animasyonu
  /// 
  /// Kullanıcı yazarken gösterilen animasyonlu dots.
  static Widget animatedTypingIndicator({
    required List<String> typingUsers,
    Duration dotDuration = const Duration(milliseconds: 600),
  }) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: Curves.easeInOut,
      child: _TypingDotsAnimation(
        typingUsers: typingUsers,
        duration: dotDuration,
      ),
    );
  }

  /// Message bubble entrance animation - mesaj balonu giriş animasyonu
  /// 
  /// Yeni mesaj geldiğinde gösterilen animasyon.
  static Widget animatedMessageEntry({
    required Widget child,
    required bool isCurrentUser,
    Duration delay = Duration.zero,
  }) {
    return AnimatedMessageEntry(
      isCurrentUser: isCurrentUser,
      delay: delay,
      child: child,
    );
  }

  /// Connection status animation - bağlantı durumu animasyonu
  /// 
  /// Online/offline durumu için animasyonlu gösterge.
  static Widget animatedConnectionStatus({
    required bool isOnline,
    required String text,
  }) {
    return AnimatedContainer(
      duration: AppAnimations.normal,
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Message reaction animation - reaksiyon animasyonu
  /// 
  /// Mesaja emoji reaksiyonu eklendiğinde gösterilen animasyon.
  static Widget animatedReaction({
    required String emoji,
    required bool isNew,
    VoidCallback? onTap,
  }) {
    return AnimatedReactionBubble(
      emoji: emoji,
      isNew: isNew,
      onTap: onTap,
    );
  }
}

/// Typing dots animation widget
/// 
/// Yazma durumunu gösteren animasyonlu noktalar.
class _TypingDotsAnimation extends StatefulWidget {
  final List<String> typingUsers;
  final Duration duration;

  const _TypingDotsAnimation({
    required this.typingUsers,
    required this.duration,
  });

  @override
  State<_TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<_TypingDotsAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: widget.duration,
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User names
          if (widget.typingUsers.isNotEmpty) ...[
            Text(
              widget.typingUsers.length == 1
                  ? '${widget.typingUsers.first} yazıyor'
                  : '${widget.typingUsers.take(2).join(', ')}${widget.typingUsers.length > 2 ? ' ve ${widget.typingUsers.length - 2} kişi daha' : ''} yazıyor',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Animated dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _animations.asMap().entries.map((entry) {
              // final index = entry.key;
              final animation = entry.value;
              
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    child: Opacity(
                      opacity: animation.value,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Animated message entry widget
/// 
/// Mesaj giriş animasyonu için kullanılan widget.
class AnimatedMessageEntry extends StatefulWidget {
  final Widget child;
  final bool isCurrentUser;
  final Duration delay;

  const AnimatedMessageEntry({
    super.key,
    required this.child,
    required this.isCurrentUser,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedMessageEntry> createState() => _AnimatedMessageEntryState();
}

class _AnimatedMessageEntryState extends State<AnimatedMessageEntry>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    
    // Slide in from right for current user, left for others
    _slideAnimation = Tween<Offset>(
      begin: widget.isCurrentUser 
          ? const Offset(1.0, 0.0) 
          : const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
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
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Animated reaction bubble
/// 
/// Mesaj reaksiyonları için animasyonlu balon.
class AnimatedReactionBubble extends StatefulWidget {
  final String emoji;
  final bool isNew;
  final VoidCallback? onTap;

  const AnimatedReactionBubble({
    super.key,
    required this.emoji,
    required this.isNew,
    this.onTap,
  });

  @override
  State<AnimatedReactionBubble> createState() => _AnimatedReactionBubbleState();
}

class _AnimatedReactionBubbleState extends State<AnimatedReactionBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    
    // If it's a new reaction, add a pulse effect
    if (widget.isNew) {
      HapticFeedback.lightImpact();
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}
