// lib/features/conversations/presentation/widgets/conversation_list_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/real_time_providers.dart';
import '../../domain/entities/conversation.dart';

class ConversationListItem extends ConsumerWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserName = conversation.getOtherParticipantName(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;
    final otherUserId = conversation.getOtherParticipantId(currentUserId);
    final typingState = ref.watch(typingIndicatorProvider);
    final isTyping = typingState['${conversation.id}:$otherUserId'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: hasUnread
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: _buildAvatar(otherUserName, hasUnread),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherUserName,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildConversationTypeIcon(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (isTyping)
              _buildTypingIndicator()
            else
              _buildLastMessage(hasUnread),
            const SizedBox(height: 2),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTimeStamp(),
            const SizedBox(height: 8),
            _buildStatusIndicators(hasUnread, unreadCount),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildAvatar(String name, bool hasUnread) {
    final initials = _getInitials(name);
    final avatarUrl = conversation.getOtherParticipantAvatarUrl(currentUserId);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasUnread
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: CircleAvatar(
        radius: hasUnread ? 24 : 26,
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        foregroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? NetworkImage(avatarUrl)
            : null,
        child: (avatarUrl == null || avatarUrl.isEmpty)
            ? Text(
                initials,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildConversationTypeIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(conversation.type.icon, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildLastMessage(bool hasUnread) {
    final lastMessage = conversation.lastMessage ?? 'No messages yet';

    return Text(
      lastMessage,
      style: TextStyle(
        color: hasUnread ? Colors.black87 : Colors.grey[600],
        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        fontSize: 14,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        SizedBox(width: 20, height: 20, child: _buildTypingAnimation()),
        const SizedBox(width: 8),
        Text(
          'typing...',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTypingDot(0),
        const SizedBox(width: 2),
        _buildTypingDot(1),
        const SizedBox(width: 2),
        _buildTypingDot(2),
      ],
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.4 + (0.6 * value),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeStamp() {
    if (conversation.lastMessageTime == null) {
      return const SizedBox.shrink();
    }

    final timeText = _formatTime(conversation.lastMessageTime!);

    return Text(
      timeText,
      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
    );
  }

  Widget _buildStatusIndicators(bool hasUnread, int unreadCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Conversation status indicator
        if (conversation.status != ConversationStatus.active)
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: Icon(
              conversation.status == ConversationStatus.closed
                  ? Icons.block
                  : Icons.archive,
              size: 12,
              color: Colors.grey[500],
            ),
          ),

        // Unread message badge
        if (hasUnread)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final first = parts[0];
      return first.isNotEmpty ? first.substring(0, 1).toUpperCase() : '?';
    }

    final firstInitial = parts[0].isNotEmpty ? parts[0].substring(0, 1) : '';
    final secondInitial = parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
    final initials = (firstInitial + secondInitial).toUpperCase();
    return initials.isNotEmpty ? initials : '?';
  }

  Color _getTypeColor() {
    switch (conversation.type) {
      case ConversationType.ticketInquiry:
        return Colors.blue;
      case ConversationType.general:
        return Colors.green;
      case ConversationType.support:
        return Colors.orange;
      case ConversationType.dispute:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

// Custom badge widget for more complex badge scenarios
class ConversationBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const ConversationBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        count > 999 ? '999+' : count.toString(),
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
