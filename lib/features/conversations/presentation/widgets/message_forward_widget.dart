// lib/features/conversations/presentation/widgets/message_forward_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';

// Mock provider for conversations - in real app, this would be imported from providers
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  // Mock conversations data
  return [
    Conversation(
      id: 'conv_1',
      participants: ['current_user', 'user_1'],
      lastMessage: 'Merhaba!',
      buyerId: 'current_user',
      sellerId: 'user_1',
      buyerName: 'Current User',
      sellerName: 'Ali Veli',
      type: ConversationType.general,
      status: ConversationStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Conversation(
      id: 'conv_2',
      participants: ['current_user', 'user_2'],
      lastMessage: 'Ne haber?',
      buyerId: 'current_user',
      sellerId: 'user_2',
      buyerName: 'Current User',
      sellerName: 'Ayşe Fatma',
      type: ConversationType.general,
      status: ConversationStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
});

/// Widget for forwarding messages to other conversations
/// Provides a list of conversations to select from for forwarding
class MessageForwardWidget extends ConsumerStatefulWidget {
  final Message message;
  final Function(List<String> conversationIds)? onForward;

  const MessageForwardWidget({
    super.key,
    required this.message,
    this.onForward,
  });

  @override
  ConsumerState<MessageForwardWidget> createState() => _MessageForwardWidgetState();
}

class _MessageForwardWidgetState extends ConsumerState<MessageForwardWidget> {
  final Set<String> _selectedConversations = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Mesajı İlet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Message preview
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  _getMessageIcon(),
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'İletilecek Mesaj:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMessagePreview(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Sohbet ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Conversations list
          Flexible(
            child: conversationsAsync.when(
              data: (conversations) {
                final filteredConversations = _searchQuery.isEmpty
                    ? conversations
                    : conversations.where((conv) {
                        final otherUserName = conv.sellerName ?? conv.buyerName ?? 'Unknown';
                        return otherUserName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filteredConversations.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Sohbet bulunamadı',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = filteredConversations[index];
                    final isSelected = _selectedConversations.contains(conversation.id);

                    final otherUserName = conversation.sellerName ?? conversation.buyerName ?? 'Unknown';
                    
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedConversations.add(conversation.id);
                          } else {
                            _selectedConversations.remove(conversation.id);
                          }
                        });
                      },
                      secondary: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          _getInitials(otherUserName),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        otherUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        conversation.lastMessage ?? 'Henüz mesaj yok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      activeColor: Theme.of(context).primaryColor,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sohbetler yüklenirken hata oluştu',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(conversationsProvider);
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Forward button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _selectedConversations.isEmpty
                  ? null
                  : () {
                      widget.onForward?.call(_selectedConversations.toList());
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedConversations.isEmpty
                    ? 'Sohbet Seçin'
                    : 'İlet (${_selectedConversations.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get appropriate icon for message type
  IconData _getMessageIcon() {
    switch (widget.message.type) {
      case MessageType.image:
        return Icons.image;
      case MessageType.file:
        return Icons.attach_file;
      case MessageType.text:
      default:
        return Icons.chat_bubble;
    }
  }

  /// Get message preview text
  String _getMessagePreview() {
    if (widget.message.content.isNotEmpty) {
      return widget.message.content;
    } else {
      switch (widget.message.type) {
        case MessageType.image:
          return '📷 Fotoğraf';
        case MessageType.file:
          return '📎 Dosya';
        case MessageType.text:
        default:
          return 'Mesaj';
      }
    }
  }

  /// Get initials from name
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
}

/// Forward confirmation dialog
class ForwardConfirmationDialog extends StatelessWidget {
  final int conversationCount;
  final String messagePreview;
  final VoidCallback onConfirm;

  const ForwardConfirmationDialog({
    super.key,
    required this.conversationCount,
    required this.messagePreview,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mesajı İlet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$conversationCount sohbete şu mesaj iletilecek:',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              messagePreview,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Devam etmek istediğinizden emin misiniz?',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('İlet'),
        ),
      ],
    );
  }
}
