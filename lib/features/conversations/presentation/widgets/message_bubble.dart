// lib/features/conversations/presentation/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/web_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message.dart';
import 'message_reactions_widget.dart';
import 'message_edit_widget.dart';
import 'message_options_sheet.dart';
import '../../../auth/presentation/screens/advanced_profile_screen.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final Function(Message)? onMessageTap;
  final Function(Message)? onMessageLongPress;
  final Widget? replyToWidget;
  final bool showTimeStamp;
  final bool isOptimistic;
  final String? senderProfileImageUrl;
  final String? senderDisplayName;
  final String? currentUserId;
  final Function(String messageId, String emoji)? onReactionTap;
  final Function(String messageId)? onAddReaction;
  final Function(Message message)? onForwardMessage;
  final Function(Message message, String newContent)? onEditMessage;
  final Function(Message message)? onDeleteMessage;
  final VoidCallback? onEditStart;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onMessageTap,
    this.onMessageLongPress,
    this.replyToWidget,
    this.showTimeStamp = true,
    this.isOptimistic = false,
    this.senderProfileImageUrl,
    this.senderDisplayName,
    this.currentUserId,
    this.onReactionTap,
    this.onAddReaction,
    this.onForwardMessage,
    this.onEditMessage,
    this.onDeleteMessage,
    this.onEditStart,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    // Always start animation to show the message
    _startOptimisticAnimation();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset(widget.isCurrentUser ? 1.0 : -1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
  }

  void _startOptimisticAnimation() {
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Edit mode'da farklı widget göster
    if (_isEditing) {
      return MessageEditWidget(
        message: widget.message,
        onSave: (newContent) {
          setState(() {
            _isEditing = false;
          });
          widget.onEditMessage?.call(widget.message, newContent);
        },
        onCancel: () {
          setState(() {
            _isEditing = false;
          });
        },
      );
    }

    // Mesaj balonlarını animasyonlu olarak göster
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildMessageContainer(),
      ),
    );
  }

  Widget _buildMessageContainer() {
    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: widget.isCurrentUser ? 64 : 8,
        right: widget.isCurrentUser ? 8 : 64,
      ),
      child: GestureDetector(
        onTap: () => widget.onMessageTap?.call(widget.message),
        onLongPress: () => _showMessageOptions(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Show profile image for other users (left side)
            if (!widget.isCurrentUser) ...[
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdvancedProfileScreen(
                        userId: widget.message.senderId,
                      ),
                    ),
                  );
                },
                child: _buildProfileAvatar(),
              ),
              const SizedBox(width: 8),
            ],
            
            // Message content
            Expanded(
              child: Align(
                alignment: widget.isCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: widget.isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (widget.replyToWidget != null) ...[
                      widget.replyToWidget!,
                      const SizedBox(height: 4),
                    ],
                    _buildMessageBubble(),
                    // Message reactions
                    if (widget.currentUserId != null &&
                        (widget.onReactionTap != null || widget.onAddReaction != null))
                      MessageReactionsWidget(
                        message: widget.message,
                        currentUserId: widget.currentUserId!,
                        onReactionTap: (emoji) => widget.onReactionTap?.call(widget.message.id, emoji),
                        onAddReaction: () => widget.onAddReaction?.call(widget.message.id),
                      ),
                    if (widget.showTimeStamp) ...[
                      const SizedBox(height: 4),
                      _buildTimeAndStatus(),
                    ],
                  ],
                ),
              ),
            ),
            
            // Show profile image for current user (right side) - optional
            if (widget.isCurrentUser) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdvancedProfileScreen(
                        userId: widget.message.senderId,
                      ),
                    ),
                  );
                },
                child: _buildProfileAvatar(isCurrentUserSide: true),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar({bool isCurrentUserSide = false}) {
    final displayName = widget.senderDisplayName ?? widget.message.senderName;
    final hasValidImage =
        widget.senderProfileImageUrl != null && widget.senderProfileImageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: isCurrentUserSide ? 16 : 18,
      backgroundColor: hasValidImage
          ? Colors.transparent
          : (widget.isCurrentUser
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.2)),
      foregroundImage: hasValidImage ? NetworkImage(widget.senderProfileImageUrl!) : null,
      child: hasValidImage
          ? null
          : Text(
              _getInitials(displayName),
              style: TextStyle(
                color: widget.isCurrentUser
                    ? AppTheme.primaryColor
                    : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
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

    final first = parts[0];
    final second = parts.length > 1 ? parts[1] : '';

    final firstInitial = first.isNotEmpty ? first.substring(0, 1) : '';
    final secondInitial = second.isNotEmpty ? second.substring(0, 1) : '';

    final initials = (firstInitial + secondInitial).toUpperCase();
    return initials.isNotEmpty ? initials : '?';
  }

  Widget _buildMessageBubble() {
    final isSystem = widget.message.type == MessageType.system;

    if (isSystem) {
      return _buildSystemMessage();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBubbleColor(),
        borderRadius: _getBubbleBorderRadius(),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageContent(),
              if (widget.message.hasAttachments) ...[
                const SizedBox(height: 8),
                _buildAttachments(),
              ],
              if (widget.message.isEdited) ...[
                const SizedBox(height: 4),
                _buildEditedIndicator(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        widget.message.content,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case MessageType.text:
        return _buildTextContent();
      case MessageType.image:
        return _buildImageContent();
      case MessageType.file:
        return _buildFileContent();
      case MessageType.offer:
        return _buildOfferContent();
      case MessageType.reminder:
        return _buildReminderContent();
      default:
        return _buildTextContent();
    }
  }

  Widget _buildTextContent() {
    return Text(
      widget.message.content,
      style: TextStyle(
        color: widget.isCurrentUser ? Colors.white : Colors.black87,
        fontSize: 16,
      ),
    );
  }

  Widget _buildImageContent() {
    if (widget.message.attachments.isEmpty) {
      return _buildTextContent();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.content.isNotEmpty) ...[
          _buildTextContent(),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: webSafeImageUrl(widget.message.attachments.first),
            height: 200,
            width: 250,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              width: 250,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              width: 250,
              color: Colors.grey[300],
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isCurrentUser
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            color: widget.isCurrentUser ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message.content.isNotEmpty
                  ? widget.message.content
                  : 'File attachment',
              style: TextStyle(
                color: widget.isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_money, color: Colors.green),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message.content,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, color: Colors.orange),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message.content,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.message.attachments.map((attachment) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isCurrentUser
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attachment,
                size: 16,
                color: widget.isCurrentUser ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Attachment',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isCurrentUser ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditedIndicator() {
    return Text(
      'edited',
      style: TextStyle(
        fontSize: 11,
        color: widget.isCurrentUser
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.grey[500],
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildTimeAndStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(widget.message.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          if (widget.isCurrentUser) ...[
            const SizedBox(width: 4),
            _buildStatusIcon(),
          ],
          if (widget.isOptimistic) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor;

    switch (widget.message.status) {
      case MessageStatus.sent:
        iconData = Icons.done;
        iconColor = Colors.grey[500]!;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        iconColor = Colors.grey[500]!;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        iconColor = AppTheme.primaryColor;
        break;
      case MessageStatus.failed:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
    }

    return Icon(iconData, size: 14, color: iconColor);
  }

  Color _getBubbleColor() {
    if (widget.message.type == MessageType.system) {
      return Colors.grey[200]!;
    }

    if (widget.isOptimistic) {
      return widget.isCurrentUser
          ? AppTheme.primaryColor.withValues(alpha: 0.7)
          : Colors.grey[300]!;
    }

    return widget.isCurrentUser ? AppTheme.primaryColor : Colors.white;
  }

  BorderRadius _getBubbleBorderRadius() {
    return BorderRadius.circular(20).copyWith(
      bottomLeft: Radius.circular(widget.isCurrentUser ? 20 : 4),
      bottomRight: Radius.circular(widget.isCurrentUser ? 4 : 20),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  void _showMessageOptions() {
    widget.onMessageLongPress?.call(widget.message);

    showModalBottomSheet(
      context: context,
      builder: (context) => MessageOptionsSheet(
        message: widget.message,
        isCurrentUser: widget.isCurrentUser,
        onForwardMessage: widget.onForwardMessage,
        onEditMessage: widget.onEditMessage,
        onDeleteMessage: widget.onDeleteMessage,
        onEditStart: () {
          setState(() {
            _isEditing = true;
          });
        },
      ),
    );
  }

}
