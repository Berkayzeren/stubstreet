// lib/features/conversations/presentation/widgets/enhanced_typing_indicator.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Enhanced typing indicator with animated dots and user info
/// Provides smooth animations and better visual feedback
class EnhancedTypingIndicator extends StatefulWidget {
  final String? userName;
  final String? userProfileImageUrl;
  final bool isVisible;
  final Duration animationDuration;
  final Color? dotColor;
  final Color? backgroundColor;
  final double? dotSize;

  const EnhancedTypingIndicator({
    super.key,
    this.userName,
    this.userProfileImageUrl,
    this.isVisible = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.dotColor,
    this.backgroundColor,
    this.dotSize = 8.0,
  });

  @override
  State<EnhancedTypingIndicator> createState() => _EnhancedTypingIndicatorState();
}

class _EnhancedTypingIndicatorState extends State<EnhancedTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller for dots
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Scale animation controller for container
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Create staggered animations for 3 dots
    _dotAnimations = List.generate(3, (index) {
      final begin = index * 0.2; // Stagger delay
      final end = begin + 0.6; // Animation duration per dot
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          begin,
          end.clamp(0.0, 1.0),
          curve: Curves.easeInOut,
        ),
      ));
    });

    // Start animations if visible
    if (widget.isVisible) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(EnhancedTypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _scaleController.forward();
    _animationController.repeat();
  }

  void _stopAnimations() {
    _scaleController.reverse();
    _animationController.stop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = widget.backgroundColor ?? 
        (isDark ? Colors.grey.shade800 : Colors.grey.shade200);
    final dotColor = widget.dotColor ?? 
        (isDark ? Colors.white70 : Colors.grey.shade600);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 64, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Profile avatar
            if (widget.userProfileImageUrl != null || widget.userName != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.userProfileImageUrl != null
                    ? NetworkImage(widget.userProfileImageUrl!)
                    : null,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                child: widget.userProfileImageUrl == null
                    ? Text(
                        _getInitials(widget.userName ?? 'U'),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],

            // Typing indicator bubble
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User name (if provided)
                    if (widget.userName != null) ...[
                      Text(
                        widget.userName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Animated dots and typing text
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated dots
                        SizedBox(
                          width: widget.dotSize! * 3 + 8, // 3 dots + spacing
                          height: widget.dotSize! * 1.5,
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(3, (index) {
                                  final animation = _dotAnimations[index];
                                  final scale = 0.5 + (animation.value * 0.5);
                                  final opacity = 0.3 + (animation.value * 0.7);
                                  
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: widget.dotSize,
                                      height: widget.dotSize,
                                      decoration: BoxDecoration(
                                        color: dotColor.withValues(alpha: opacity),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Typing text with fade animation
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final opacity = (math.sin(_animationController.value * 2 * math.pi) + 1) / 2;
                            return Opacity(
                              opacity: 0.5 + (opacity * 0.5),
                              child: Text(
                                'yazıyor...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: dotColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';

    final first = parts[0];
    final second = parts.length > 1 ? parts[1] : '';

    final firstInitial = first.isNotEmpty ? first.substring(0, 1) : '';
    final secondInitial = second.isNotEmpty ? second.substring(0, 1) : '';

    final initials = (firstInitial + secondInitial).toUpperCase();
    return initials.isNotEmpty ? initials : 'U';
  }
}

/// Compact typing indicator for list items
/// Shows a simple animated indicator without user info
class CompactTypingIndicator extends StatefulWidget {
  final bool isVisible;
  final Color? color;
  final double size;

  const CompactTypingIndicator({
    super.key,
    this.isVisible = true,
    this.color,
    this.size = 12.0,
  });

  @override
  State<CompactTypingIndicator> createState() => _CompactTypingIndicatorState();
}

class _CompactTypingIndicatorState extends State<CompactTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animations = List.generate(3, (index) {
      final begin = index * 0.2;
      final end = begin + 0.4;
      
      return Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          begin,
          end.clamp(0.0, 1.0),
          curve: Curves.easeInOut,
        ),
      ));
    });

    if (widget.isVisible) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CompactTypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final color = widget.color ?? Theme.of(context).primaryColor;

    return SizedBox(
      width: widget.size * 3 + 4, // 3 dots + spacing
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final animation = _animations[index];
              return Opacity(
                opacity: animation.value,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Typing indicator for input field
/// Shows when user is typing in the input field
class InputTypingIndicator extends StatefulWidget {
  final bool isTyping;
  final String? typingText;
  final Duration showDuration;

  const InputTypingIndicator({
    super.key,
    this.isTyping = false,
    this.typingText,
    this.showDuration = const Duration(seconds: 3),
  });

  @override
  State<InputTypingIndicator> createState() => _InputTypingIndicatorState();
}

class _InputTypingIndicatorState extends State<InputTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    if (widget.isTyping) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(InputTypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CompactTypingIndicator(
                isVisible: widget.isTyping,
                color: theme.primaryColor,
                size: 8,
              ),
              const SizedBox(width: 8),
              Text(
                widget.typingText ?? 'Yazıyor...',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
