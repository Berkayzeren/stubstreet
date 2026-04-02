// lib/features/conversations/presentation/widgets/message_reply_preview.dart

import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';

/// Widget that shows a preview of the message being replied to
/// 
/// This widget displays:
/// - Original message content (truncated if too long)
/// - Original sender name
/// - Message type indicator
/// - Clear button to cancel reply
class MessageReplyPreview extends StatelessWidget {
  final Message message;
  final VoidCallback onClear;
  final int maxContentLength;

  const MessageReplyPreview({
    super.key,
    required this.message,
    required this.onClear,
    this.maxContentLength = 100,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: theme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Reply icon
          Icon(
            Icons.reply,
            color: theme.primaryColor,
            size: 20,
          ),
          
          const SizedBox(width: 12),
          
          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name and message type
                Row(
                  children: [
                    Text(
                      'Replying to ${message.senderName}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    if (message.type != MessageType.text) ...[
                      const SizedBox(width: 8),
                      _buildMessageTypeIndicator(message.type, theme),
                    ],
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Message content preview
                Text(
                  _getPreviewContent(),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Clear button
          IconButton(
            onPressed: onClear,
            icon: Icon(
              Icons.close,
              color: theme.hintColor,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            tooltip: 'Cancel reply',
          ),
        ],
      ),
    );
  }

  /// Get preview content based on message type
  String _getPreviewContent() {
    switch (message.type) {
      case MessageType.text:
        return message.content.length > maxContentLength
            ? '${message.content.substring(0, maxContentLength)}...'
            : message.content;
            
      case MessageType.image:
        return '📷 Image';
        
      case MessageType.file:
        return '📎 File attachment';
        
      case MessageType.system:
        return '⚙️ System message';
        
      case MessageType.offer:
        return '💰 Offer: ${message.content}';
        
      case MessageType.reminder:
        return '⏰ Reminder: ${message.content}';
    }
  }

  /// Build message type indicator
  Widget _buildMessageTypeIndicator(MessageType type, ThemeData theme) {
    IconData icon;
    Color color;
    
    switch (type) {
      case MessageType.image:
        icon = Icons.image;
        color = Colors.green;
        break;
      case MessageType.file:
        icon = Icons.attach_file;
        color = Colors.blue;
        break;
      case MessageType.system:
        icon = Icons.settings;
        color = Colors.orange;
        break;
      case MessageType.offer:
        icon = Icons.monetization_on;
        color = Colors.amber;
        break;
      case MessageType.reminder:
        icon = Icons.schedule;
        color = Colors.purple;
        break;
      default:
        icon = Icons.message;
        color = theme.primaryColor;
    }
    
    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }
}
