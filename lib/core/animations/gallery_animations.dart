// lib/core/animations/gallery_animations.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_animations.dart';

/// Gallery and media animations
/// 
/// Bu sınıf galeri ve media ile ilgili animasyonları içerir.
/// Resim görüntüleme, zoom, swipe ve geçiş animasyonları sağlar.
class GalleryAnimations {
  
  /// Hero animation for image gallery
  /// 
  /// Resim galerisi için hero transition
  static Widget heroImageTransition({
    required String heroTag,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: child,
      ),
    );
  }

  /// Zoom animation for images
  /// 
  /// Resimler için zoom animasyonu
  static Widget zoomableImage({
    required Widget child,
    double maxScale = 3.0,
    double minScale = 1.0,
  }) {
    return InteractiveViewer(
      maxScale: maxScale,
      minScale: minScale,
      child: child,
    );
  }

  /// Page view with custom transitions
  /// 
  /// Özel geçişli sayfa görünümü
  static Widget customPageView({
    required PageController controller,
    required List<Widget> children,
    PageTransition transition = PageTransition.slide,
  }) {
    return PageView.builder(
      controller: controller,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return AnimatedPageItem(
          transition: transition,
          child: children[index],
        );
      },
    );
  }
}

/// Page transition types
enum PageTransition {
  slide,
  fade,
  scale,
  rotate,
}

/// Animated page item widget
class AnimatedPageItem extends StatefulWidget {
  final Widget child;
  final PageTransition transition;

  const AnimatedPageItem({
    super.key,
    required this.child,
    required this.transition,
  });

  @override
  State<AnimatedPageItem> createState() => _AnimatedPageItemState();
}

class _AnimatedPageItemState extends State<AnimatedPageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
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
      animation: _animation,
      builder: (context, child) {
        switch (widget.transition) {
          case PageTransition.fade:
            return FadeTransition(
              opacity: _animation,
              child: widget.child,
            );
          
          case PageTransition.scale:
            return ScaleTransition(
              scale: _animation,
              child: widget.child,
            );
          
          case PageTransition.rotate:
            return RotationTransition(
              turns: _animation,
              child: widget.child,
            );
          
          case PageTransition.slide:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(_animation),
              child: widget.child,
            );
        }
      },
    );
  }
}

/// Gallery overlay widget
class GalleryOverlay extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String? heroTag;

  const GalleryOverlay({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.heroTag,
  });

  @override
  State<GalleryOverlay> createState() => _GalleryOverlayState();
}

class _GalleryOverlayState extends State<GalleryOverlay>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    _fadeController = AnimationController(
      duration: AppAnimations.normal,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  void _closeGallery() {
    HapticFeedback.lightImpact();
    _fadeController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Main image viewer
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: _toggleOverlay,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: InteractiveViewer(
                        maxScale: 3.0,
                        minScale: 1.0,
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: widget.heroTag != null && index == widget.initialIndex
                              ? Hero(
                                  tag: widget.heroTag!,
                                  child: Image.network(
                                    widget.images[index],
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Image.network(
                                  widget.images[index],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Overlay controls
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: AppAnimations.fast,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_currentIndex + 1} / ${widget.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            GestureDetector(
                              onTap: _closeGallery,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Bottom indicators
                      if (widget.images.length > 1)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.images.length,
                              (index) => AnimatedContainer(
                                duration: AppAnimations.fast,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentIndex == index ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentIndex == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
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
    );
  }
}

/// Animated image card widget
class AnimatedImageCard extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final String? heroTag;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AnimatedImageCard({
    super.key,
    required this.imageUrl,
    this.width = 100,
    this.height = 100,
    this.heroTag,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<AnimatedImageCard> createState() => _AnimatedImageCardState();
}

class _AnimatedImageCardState extends State<AnimatedImageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.heroTag != null
                ? Hero(
                    tag: widget.heroTag!,
                    child: _buildImageContainer(),
                  )
                : _buildImageContainer(),
          );
        },
      ),
    );
  }

  Widget _buildImageContainer() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.error,
                color: Colors.grey,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }
}
