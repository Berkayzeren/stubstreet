import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/web_image.dart';
import 'package:swipe_to/swipe_to.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message.dart';

class EnhancedMessageBubble extends StatefulWidget {
  final Message message;
  final bool isCurrentUser;
  final Function(Message)? onMessageTap;
  final Function(Message)? onMessageLongPress;
  final Function(Message)? onSwipeToReply;
  final Message? replyToMessage;
  final bool showTimeStamp;
  final bool isOptimistic;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onSwipeToReply,
    this.replyToMessage,
    this.showTimeStamp = true,
    this.isOptimistic = false,
  });

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    if (widget.isOptimistic) {
      _startOptimisticAnimation();
    }
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

    _slideAnimation = Tween<Offset>(
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
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildSwipeToReplyWrapper(),
      ),
    );
  }

  Widget _buildSwipeToReplyWrapper() {
    return SwipeTo(
      onRightSwipe: (details) {
        if (widget.onSwipeToReply != null) {
          widget.onSwipeToReply!(widget.message);
          HapticFeedback.selectionClick();
        }
      },
      onLeftSwipe: (details) {
        if (widget.onSwipeToReply != null) {
          widget.onSwipeToReply!(widget.message);
          HapticFeedback.selectionClick();
        }
      },
      rightSwipeWidget: const Icon(
        Icons.reply,
        color: Colors.grey,
      ),
      leftSwipeWidget: const Icon(
        Icons.reply,
        color: Colors.grey,
      ),
      child: _buildMessageContainer(),
    );
  }

  Widget _buildMessageContainer() {
    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: widget.isCurrentUser ? 64 : 0,
        right: widget.isCurrentUser ? 0 : 64,
      ),
      child: GestureDetector(
        onTap: () => widget.onMessageTap?.call(widget.message),
        onLongPress: () => _showMessageOptions(),
        child: Align(
          alignment: widget.isCurrentUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: widget.isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (widget.replyToMessage != null) ...[ 
                _buildReplyPreview(),
                const SizedBox(height: 4),
              ],
              _buildMessageBubble(),
              if (widget.showTimeStamp) ...[
                const SizedBox(height: 4),
                _buildTimeAndStatus(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final replyMessage = widget.replyToMessage!;
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: widget.isCurrentUser ? Colors.white : AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyMessage.senderName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: widget.isCurrentUser ? Colors.white70 : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _getReplyPreviewText(replyMessage),
            style: TextStyle(
              fontSize: 12,
              color: widget.isCurrentUser ? Colors.white54 : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getReplyPreviewText(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.offer:
        return '💰 Offer';
      case MessageType.reminder:
        return '⏰ Reminder';
      case MessageType.system:
        return '🔧 System message';
    }
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
      child: Column(
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
    return SelectableText(
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
      builder: (context) => _MessageOptionsSheet(
        message: widget.message,
        isCurrentUser: widget.isCurrentUser,
        onReply: widget.onSwipeToReply,
      ),
    );
  }
}

class _MessageOptionsSheet extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final Function(Message)? onReply;

  const _MessageOptionsSheet({
    required this.message,
    required this.isCurrentUser,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _buildOptionTile(
            icon: Icons.copy,
            title: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.content));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message copied to clipboard')),
              );
            },
          ),
          _buildOptionTile(
            icon: Icons.reply,
            title: 'Reply',
            onTap: () {
              Navigator.pop(context);
              onReply?.call(message);
            },
          ),
          if (isCurrentUser) ...[
            _buildOptionTile(
              icon: Icons.edit,
              title: 'Edit',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit functionality
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'Delete',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete functionality
              },
              isDestructive: true,
            ),
          ],
          _buildOptionTile(
            icon: Icons.info,
            title: 'Info',
            onTap: () {
              Navigator.pop(context);
              _showMessageInfo(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : null),
      ),
      onTap: onTap,
    );
  }

  void _showMessageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', message.type.displayName),
            _buildInfoRow('Status', message.status.displayName),
            _buildInfoRow('Sent', _formatDateTime(message.createdAt)),
            if (message.readAt != null)
              _buildInfoRow('Read', _formatDateTime(message.readAt!)),
            if (message.isEdited)
              _buildInfoRow(
                'Edited',
                message.updatedAt != null
                    ? _formatDateTime(message.updatedAt!)
                    : 'Yes',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
