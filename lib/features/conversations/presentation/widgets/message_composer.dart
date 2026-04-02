// lib/features/conversations/presentation/widgets/message_composer.dart

import 'package:flutter/material.dart';
import '../../../../core/animations/app_animations.dart';

/// Enhanced message composer widget with attachment capabilities
/// 
/// This widget provides:
/// - Text input with character counter
/// - Send button with loading state
/// - File and image attachment buttons
/// - Typing indicator integration
/// - Accessibility support
/// - Adaptive design for different screen sizes
class MessageComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onAttachFile;
  final VoidCallback? onAttachImage;
  final bool isTyping;
  final bool isOnline;
  final int maxCharacters;
  final String hintText;

  const MessageComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onAttachFile,
    this.onAttachImage,
    this.isTyping = false,
    this.isOnline = true,
    this.maxCharacters = 5000,
    this.hintText = 'Type a message...',
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer>
    with TickerProviderStateMixin {
  
  late AnimationController _attachmentAnimationController;
  late Animation<double> _attachmentAnimation;
  bool _showAttachments = false;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _attachmentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _attachmentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _attachmentAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Listen to text changes
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _attachmentAnimationController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = widget.controller.text.trim().isNotEmpty && widget.isOnline;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  void _toggleAttachments() {
    setState(() {
      _showAttachments = !_showAttachments;
    });
    
    if (_showAttachments) {
      _attachmentAnimationController.forward();
    } else {
      _attachmentAnimationController.reverse();
    }
  }

  void _onSendPressed() {
    if (_canSend) {
      widget.onSend();
      setState(() {
        _canSend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textLength = widget.controller.text.length;
    final isNearLimit = textLength > widget.maxCharacters * 0.9;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment options
          AnimatedBuilder(
            animation: _attachmentAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _attachmentAnimation.value,
                  child: child,
                ),
              );
            },
            child: _buildAttachmentOptions(),
          ),
          
          // Main composer
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button
                if (widget.onAttachFile != null || widget.onAttachImage != null)
                  IconButton(
                    onPressed: widget.isOnline ? _toggleAttachments : null,
                    icon: AnimatedRotation(
                      turns: _showAttachments ? 0.125 : 0, // 45 degrees
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.add,
                        color: widget.isOnline 
                            ? theme.primaryColor 
                            : theme.disabledColor,
                      ),
                    ),
                    tooltip: 'Add attachment',
                  ),
                
                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 120,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isTyping 
                            ? theme.primaryColor.withValues(alpha: 0.5)
                            : theme.dividerColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          enabled: widget.isOnline,
                          maxLines: null,
                          maxLength: widget.maxCharacters,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: widget.isOnline 
                                ? widget.hintText 
                                : 'No connection...',
                            hintStyle: TextStyle(
                              color: theme.hintColor.withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            counterText: '', // Hide default counter
                          ),
                          style: TextStyle(
                            color: widget.isOnline 
                                ? theme.textTheme.bodyLarge?.color
                                : theme.disabledColor,
                          ),
                        ),
                        
                        // Character counter
                        if (isNearLimit)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 16,
                              bottom: 4,
                            ),
                            child: Text(
                              '${widget.maxCharacters - textLength}',
                              style: TextStyle(
                                fontSize: 12,
                                color: textLength >= widget.maxCharacters
                                    ? Colors.red
                                    : theme.hintColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send button with enhanced animations
                AnimatedButton(
                  onPressed: _canSend ? _onSendPressed : null,
                  backgroundColor: _canSend 
                      ? theme.primaryColor 
                      : theme.disabledColor.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                  borderRadius: BorderRadius.circular(20),
                  elevation: _canSend ? 4 : 0,
                  child: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build attachment options panel
  Widget _buildAttachmentOptions() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // File attachment
          if (widget.onAttachFile != null)
            _AttachmentOption(
              icon: Icons.insert_drive_file,
              label: 'File',
              color: theme.primaryColor,
              onTap: () {
                _toggleAttachments();
                widget.onAttachFile?.call();
              },
            ),
          
          // Image attachment  
          if (widget.onAttachImage != null)
            _AttachmentOption(
              icon: Icons.image,
              label: 'Photo',
              color: Colors.green,
              onTap: () {
                _toggleAttachments();
                widget.onAttachImage?.call();
              },
            ),
          
          // Camera (future enhancement)
          _AttachmentOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            color: Colors.blue,
            onTap: () {
              _toggleAttachments();
              // TODO: Implement camera functionality
            },
          ),
          
          // Location (future enhancement)
          _AttachmentOption(
            icon: Icons.location_on,
            label: 'Location',
            color: Colors.red,
            onTap: () {
              _toggleAttachments();
              // TODO: Implement location sharing
            },
          ),
        ],
      ),
    );
  }
}

/// Individual attachment option widget
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
