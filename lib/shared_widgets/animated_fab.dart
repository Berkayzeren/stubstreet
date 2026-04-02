// lib/shared_widgets/animated_fab.dart

import 'package:flutter/material.dart';

/// Enhanced animated floating action button with modern design and animations
/// This widget provides subtle animations and modern styling for better user experience
class AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final bool isExtended;
  final String? heroTag;

  const AnimatedFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.shape,
    this.isExtended = false,
    this.heroTag,
  });

  @override
  State<AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<AnimatedFab>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for tap feedback
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    // Pulse animation for subtle breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start subtle pulse animation
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Provide haptic feedback and scale animation
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: (widget.backgroundColor ?? theme.primaryColor)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: (widget.backgroundColor ?? theme.primaryColor)
                      .withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: widget.isExtended
                ? FloatingActionButton.extended(
                    heroTag: widget.heroTag,
                    onPressed: _handleTap,
                    icon: widget.icon,
                    label: Text(widget.label ?? ''),
                    backgroundColor: widget.backgroundColor ?? theme.primaryColor,
                    foregroundColor: widget.foregroundColor ?? Colors.white,
                    elevation: widget.elevation ?? 8,
                    shape: widget.shape ?? 
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                  )
                : FloatingActionButton(
                    heroTag: widget.heroTag,
                    onPressed: _handleTap,
                    backgroundColor: widget.backgroundColor ?? theme.primaryColor,
                    foregroundColor: widget.foregroundColor ?? Colors.white,
                    elevation: widget.elevation ?? 8,
                    shape: widget.shape ??
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                    child: widget.icon,
                  ),
          ),
        );
      },
    );
  }
}

/// Enhanced animated card with hover and scale effects
/// Provides modern interactions for card-based UI elements
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final bool enableHoverEffect;
  final bool enableScaleAnimation;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.color,
    this.elevation,
    this.shape,
    this.enableHoverEffect = true,
    this.enableScaleAnimation = true,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  // Removed _isHovered field - hover state is tracked by _hoverController.value

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2,
      end: (widget.elevation ?? 2) + 4,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    if (!widget.enableHoverEffect) return;
    
    // Hover state is managed by the AnimationController (_hoverController.value)
    
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.enableScaleAnimation ? _scaleAnimation.value : 1.0,
            child: Card(
              margin: widget.margin,
              color: widget.color,
              elevation: _elevationAnimation.value,
              shape: widget.shape,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: widget.shape is RoundedRectangleBorder
                    ? (widget.shape as RoundedRectangleBorder).borderRadius as BorderRadius?
                    : BorderRadius.circular(12),
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
