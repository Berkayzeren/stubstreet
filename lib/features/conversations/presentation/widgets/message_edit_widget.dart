// lib/features/conversations/presentation/widgets/message_edit_widget.dart

import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';

/// Widget for editing messages in chat
/// Provides inline editing functionality with save/cancel options
class MessageEditWidget extends StatefulWidget {
  final Message message;
  final Function(String newContent)? onSave;
  final VoidCallback? onCancel;

  const MessageEditWidget({
    super.key,
    required this.message,
    this.onSave,
    this.onCancel,
  });

  @override
  State<MessageEditWidget> createState() => _MessageEditWidgetState();
}

class _MessageEditWidgetState extends State<MessageEditWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
    _focusNode = FocusNode();
    
    // Auto focus when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Select all text
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Use theme to keep consistent styling throughout the editor
    final isCurrentUser = widget.message.senderId == 'current_user'; // TODO: Get from auth

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isCurrentUser ? 64 : 8,
        right: isCurrentUser ? 8 : 64,
      ),
      child: Column(
        crossAxisAlignment: isCurrentUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          // Edit header
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mesajı düzenle',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Edit input container
          Container(
            constraints: const BoxConstraints(
              maxWidth: 280,
              minWidth: 120,
            ),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? theme.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.primaryColor,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Text input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Mesajınızı düzenleyin...',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: isCurrentUser 
                          ? theme.primaryColor
                          : Colors.black87,
                    ),
                    onSubmitted: (_) => _saveMessage(),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: _isLoading ? null : widget.onCancel,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 32),
                        ),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Save button
                      ElevatedButton(
                        onPressed: _isLoading || _controller.text.trim().isEmpty
                            ? null
                            : _saveMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Kaydet',
                                style: TextStyle(fontSize: 14),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Helper text
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Enter ile kaydet • Escape ile iptal et',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveMessage() {
    final newContent = _controller.text.trim();
    
    if (newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj boş olamaz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newContent == widget.message.content) {
      // No changes made
      widget.onCancel?.call();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate save delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        widget.onSave?.call(newContent);
      }
    });
  }
}

/// Confirmation dialog for message deletion
class MessageDeleteDialog extends StatelessWidget {
  final Message message;
  final VoidCallback? onConfirm;

  const MessageDeleteDialog({
    super.key,
    required this.message,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Remove unused theme variable since it's not needed in this widget
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.delete_outline,
            color: Colors.red.shade600,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Mesajı Sil'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bu mesajı silmek istediğinizden emin misiniz?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          // Message preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Silinecek mesaj:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu işlem geri alınamaz',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İptal',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sil'),
        ),
      ],
    );
  }
}
