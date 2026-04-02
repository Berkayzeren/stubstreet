// lib/core/animations/enhanced_loading.dart

import 'package:flutter/material.dart';
import 'app_animations.dart';

/// Enhanced loading states with animations
/// 
/// Bu sınıf loading durumları için gelişmiş animasyonlu widget'lar sağlar.
/// Geleneksel CircularProgressIndicator yerine daha kullanıcı dostu
/// skeleton loading ve shimmer efektleri sunar.
class EnhancedLoading {
  
  /// Skeleton loading for message list
  /// 
  /// Mesaj listesi yüklenirken gösterilen skeleton.
  static Widget messageListSkeleton({
    int itemCount = 5,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final isCurrentUser = index % 2 == 0;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: isCurrentUser 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            children: [
              if (!isCurrentUser) ...[
                SkeletonLoader(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(width: 8),
              ],
              
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: isCurrentUser 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: 80 + (index % 3 * 40),
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 4),
                    SkeletonLoader(
                      width: 60 + (index % 2 * 20),
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
              
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                SkeletonLoader(
                  width: 32,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Skeleton loading for profile
  /// 
  /// Profil bilgileri yüklenirken gösterilen skeleton.
  static Widget profileSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile picture
          const SkeletonLoader(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          const SkeletonLoader(
            width: 120,
            height: 20,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          
          const SizedBox(height: 8),
          
          // Email
          const SkeletonLoader(
            width: 180,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return const SkeletonLoader(
                width: 80,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Skeleton loading for ticket list
  /// 
  /// Bilet listesi yüklenirken gösterilen skeleton.
  static Widget ticketListSkeleton({
    int itemCount = 4,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event title
              const SkeletonLoader(
                width: double.infinity,
                height: 20,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              
              const SizedBox(height: 12),
              
              // Event details
              Row(
                children: [
                  const SkeletonLoader(
                    width: 60,
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                  ),
                  const SizedBox(width: 16),
                  const SkeletonLoader(
                    width: 80,
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Price and quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SkeletonLoader(
                    width: 100,
                    height: 18,
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                  const SkeletonLoader(
                    width: 60,
                    height: 16,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shimmer loading for search results
  /// 
  /// Arama sonuçları için shimmer efekti.
  static Widget searchResultsSkeleton({
    int itemCount = 6,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // Event image
              const SkeletonLoader(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              
              const SizedBox(width: 12),
              
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    const SkeletonLoader(
                      width: 120,
                      height: 14,
                      borderRadius: BorderRadius.all(Radius.circular(7)),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    const SkeletonLoader(
                      width: 80,
                      height: 12,
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                  ],
                ),
              ),
              
              // Price
              const SkeletonLoader(
                width: 60,
                height: 20,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pulse loading for buttons
  /// 
  /// Butonlar için nabız loading efekti.
  static Widget buttonPulseLoading({
    required String text,
    Color? color,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: PulseLoadingButton(
        text: text,
        color: color,
      ),
    );
  }

  /// Typing animation for text fields
  /// 
  /// Text field'lar için typing animasyonu.
  static Widget typingAnimation({
    required String text,
    Duration duration = const Duration(milliseconds: 50),
    TextStyle? style,
  }) {
    return TypingTextAnimation(
      text: text,
      duration: duration,
      style: style,
    );
  }
}

/// Pulse loading button widget
class PulseLoadingButton extends StatefulWidget {
  final String text;
  final Color? color;

  const PulseLoadingButton({
    super.key,
    required this.text,
    this.color,
  });

  @override
  State<PulseLoadingButton> createState() => _PulseLoadingButtonState();
}

class _PulseLoadingButtonState extends State<PulseLoadingButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat(reverse: true);
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
        return Opacity(
          opacity: _animation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: widget.color ?? Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

/// Typing text animation widget
class TypingTextAnimation extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle? style;

  const TypingTextAnimation({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 50),
    this.style,
  });

  @override
  State<TypingTextAnimation> createState() => _TypingTextAnimationState();
}

class _TypingTextAnimationState extends State<TypingTextAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration * widget.text.length,
      vsync: this,
    );
    
    _animation = IntTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
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
        final visibleText = widget.text.substring(0, _animation.value);
        
        return RichText(
          text: TextSpan(
            style: widget.style ?? DefaultTextStyle.of(context).style,
            children: [
              TextSpan(text: visibleText),
              TextSpan(
                text: '|',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
