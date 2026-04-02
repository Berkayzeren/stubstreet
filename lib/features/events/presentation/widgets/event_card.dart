// lib/features/events/presentation/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/event.dart';
import '../../../../core/utils/web_image.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';

/// EventCard widget that displays event information with like functionality
/// Converted to StatefulWidget to maintain like state independently for each card
class EventCard extends ConsumerStatefulWidget {
  final EventItem event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard> {
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    // Initialize like state from event data
    // Each card maintains its own like state independent of others
    final cache = ref.read(genericLikeStateCacheProvider);
    isLiked = cache[widget.event.id] ?? widget.event.isLiked;
    likeCount = widget.event.likeCount;
  }

  /// Toggle like state for this specific event card
  /// This maintains state within the card and provides immediate feedback
  void _toggleLike() {
    final current = ref.read(genericLikeStateCacheProvider)[widget.event.id] ?? isLiked;
    final next = !current;
    setState(() {
      if (next) {
        likeCount++;
        isLiked = true;
      } else {
        likeCount = likeCount > 0 ? likeCount - 1 : 0;
        isLiked = false;
      }
    });

    // Update global like cache so other screens/cards stay in sync
    ref.read(genericLikeStateCacheProvider.notifier).setLikeState(widget.event.id, next);

    // Provide haptic feedback for better user experience
    HapticFeedback.lightImpact();

    // Optional: In a real app, you would also send the like/unlike action to backend here
    // Example: await eventService.toggleLike(widget.event.id, isLiked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cached = ref.watch(genericLikeStateCacheProvider);
    final effectiveIsLiked = cached[widget.event.id] ?? isLiked;
    
    // Enhanced dark theme support with better colors and visibility
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 8 : 4,
      color: isDark ? Colors.grey[850] : null,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: theme.primaryColor.withValues(alpha: 0.1),
        highlightColor: theme.primaryColor.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      webSafeImageUrl(widget.event.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Event image load error: $error for URL: ${widget.event.imageUrl}');
                        return Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: Icon(
                            Icons.event,
                            size: 48,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  // Genre badge if available
                  if (widget.event.genre != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.event.genre!.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  
                  // Like button positioned on top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _toggleLike,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  effectiveIsLiked ? Icons.favorite : Icons.favorite_border,
                                  color: effectiveIsLiked ? Colors.red : Colors.white,
                                  size: 18,
                                ),
                                if (likeCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '$likeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // Default placeholder with category-based color
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withValues(alpha: 0.7),
                      theme.primaryColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.event,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced title with better dark theme support - Always visible
                  Text(
                    widget.event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Enhanced date with icon and better visibility
                  if (widget.event.dateTime != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${DateFormat('dd MMM yyyy', 'tr_TR').format(widget.event.dateTime!.toLocal())} • ${DateFormat('HH:mm', 'tr_TR').format(widget.event.dateTime!.toLocal())}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[300] : Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  // Enhanced venue with icon and better spacing
                  if (widget.event.venueName != null || widget.event.city != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [widget.event.venueName, widget.event.city]
                                .whereType<String>()
                                .where((e) => e.isNotEmpty)
                                .join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[300] : Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // Price range if available
                  if (widget.event.priceRange != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.event.priceRange!,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


