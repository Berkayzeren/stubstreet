// lib/features/conversations/presentation/widgets/message_reactions_widget.dart

import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';

/// Widget to display and manage message reactions (emoji responses)
/// Shows reaction counts and allows users to add/remove reactions
class MessageReactionsWidget extends StatelessWidget {
  final Message message;
  final String currentUserId;
  final Function(String emoji) onReactionTap;
  final VoidCallback onAddReaction;

  const MessageReactionsWidget({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onReactionTap,
    required this.onAddReaction,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show anything if there are no reactions
    if (message.reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          // Show existing reactions
          ...message.reactions.entries
              .where((entry) => entry.value.isNotEmpty)
              .map((entry) => _buildReactionChip(
                    context,
                    entry.key,
                    entry.value,
                  )),
          
          // Add reaction button
          _buildAddReactionButton(context),
        ],
      ),
    );
  }

  /// Build individual reaction chip showing emoji and count
  Widget _buildReactionChip(
    BuildContext context,
    String emoji,
    List<String> userIds,
  ) {
    final isCurrentUserReacted = userIds.contains(currentUserId);
    final count = userIds.length;

    return GestureDetector(
      onTap: () => onReactionTap(emoji),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrentUserReacted
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          border: Border.all(
            color: isCurrentUserReacted
                ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 14),
            ),
            if (count > 1) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCurrentUserReacted
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the add reaction button (+ icon)
  Widget _buildAddReactionButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddReaction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.add,
          size: 16,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting reactions with popular emojis
class ReactionPickerBottomSheet extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const ReactionPickerBottomSheet({
    super.key,
    required this.onEmojiSelected,
  });

  // Popular reaction emojis
  static const List<String> _popularReactions = [
    '👍', '❤️', '😂', '😮', '😢', '😡', '👏', '🔥',
    '💯', '✨', '👌', '🤝', '💪', '🎉', '😍', '🤔',
    '😊', '😎', '🙈', '🙌', '💕', '⚡', '🚀', '🎊',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Tepki Seç',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Emoji grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _popularReactions.length,
            itemBuilder: (context, index) {
              final emoji = _popularReactions[index];
              return GestureDetector(
                onTap: () {
                  onEmojiSelected(emoji);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // More emojis button
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Could open full emoji picker here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Daha fazla emoji yakında eklenecek'),
                ),
              );
            },
            icon: const Icon(Icons.emoji_emotions),
            label: const Text('Daha Fazla Emoji'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
