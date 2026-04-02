import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../l10n/app_localizations.dart';

class AnimatedHomeHeader extends StatefulWidget {
  final String userName;
  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  
  const AnimatedHomeHeader({
    super.key,
    required this.userName,
    this.onSearchTap,
    this.onFilterTap,
  });

  @override
  State<AnimatedHomeHeader> createState() => _AnimatedHomeHeaderState();
}

class _AnimatedHomeHeaderState extends State<AnimatedHomeHeader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _waveController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment(
                      0.8 + 0.2 * math.sin(_waveController.value * 2 * math.pi),
                      1.0,
                    ),
                    colors: isDark
                        ? [
                            theme.primaryColor.withValues(alpha: 0.3),
                            theme.primaryColor.withValues(alpha: 0.1),
                            Colors.transparent,
                          ]
                        : [
                            theme.primaryColor.withValues(alpha: 0.15),
                            theme.primaryColor.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                  ),
                ),
              );
            },
          ),
          
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _waveController.value * 2 * math.pi,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.1),
                          theme.primaryColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
                                      Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        _getGreetingIcon(),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _getGreeting(),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: isDark 
                                            ? Colors.white.withValues(alpha: 0.9)
                                            : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  widget.userName,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: isDark 
                                        ? Colors.white
                                        : theme.primaryColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.todaysEventQuestion,
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Search bar
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: GestureDetector(
                      onTap: widget.onSearchTap,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 20),
                            Icon(
                              Icons.search,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.searchEventsPlaceholder,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: widget.onFilterTap,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 18) {
      return 'İyi günler';
    } else {
      return 'İyi akşamlar';
    }
  }
  
  String _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '🌙'; // Gece
    } else if (hour < 12) {
      return '☀️'; // Sabah
    } else if (hour < 18) {
      return '🌞'; // Öğlen
    } else if (hour < 21) {
      return '🌅'; // Akşam
    } else {
      return '🌜'; // Gece
    }
  }
}
