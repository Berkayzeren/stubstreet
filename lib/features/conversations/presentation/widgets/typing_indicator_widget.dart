// lib/features/conversations/presentation/widgets/typing_indicator_widget.dart

import 'package:flutter/material.dart';

/// Animated typing indicator widget
/// 
/// This widget shows when other users are typing in the conversation
/// with a smooth animation and user names display.
class TypingIndicatorWidget extends StatefulWidget {
  final List<String> typingUsers;
  final Duration animationDuration;

  const TypingIndicatorWidget({
    super.key,
    required this.typingUsers,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Dot animation controllers for the typing dots
    _dotControllers = List.generate(3, (index) {
      return AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );
    });
    
    // Staggered dot animations
    _dotAnimations = _dotControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(
            index * 0.2, // Stagger delay
            0.8 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      );
    }).toList();
    
    // Start animations if users are typing
    if (widget.typingUsers.isNotEmpty) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(TypingIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.typingUsers.isNotEmpty && oldWidget.typingUsers.isEmpty) {
      _startAnimations();
    } else if (widget.typingUsers.isEmpty && oldWidget.typingUsers.isNotEmpty) {
      _stopAnimations();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startAnimations() {
    _animationController.forward();
    
    // Start dot animations with staggered timing
    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    _animationController.reverse();
    
    for (final controller in _dotControllers) {
      controller.stop();
      controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animationController,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(_animationController),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Typing indicator bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Typing users text
                  Text(
                    _getTypingText(),
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Animated dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_dotAnimations.length, (index) {
                      final animation = _dotAnimations[index];
                      
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.5 + (animation.value * 0.5),
                            child: Container(
                              margin: EdgeInsets.only(
                                right: index < 2 ? 4 : 0,
                              ),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.3 + (animation.value * 0.7),
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // User avatar(s) - for future enhancement
            _buildUserAvatars(theme),
          ],
        ),
      ),
    );
  }

  /// Generate typing text based on number of users
  String _getTypingText() {
    if (widget.typingUsers.isEmpty) return '';
    
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first} is typing...';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers.first} and ${widget.typingUsers.last} are typing...';
    } else {
      return '${widget.typingUsers.first} and ${widget.typingUsers.length - 1} others are typing...';
    }
  }

  /// Build user avatars for typing users (future enhancement)
  Widget _buildUserAvatars(ThemeData theme) {
    if (widget.typingUsers.length == 1) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
        child: Text(
          widget.typingUsers.first[0].toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      );
    }
    
    // For multiple users, show a stack of avatars
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: widget.typingUsers.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          
          return Positioned(
            left: index * 8.0,
            child: CircleAvatar(
              radius: 8,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
              child: Text(
                user[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
