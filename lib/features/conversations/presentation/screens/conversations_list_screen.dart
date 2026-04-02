// lib/features/conversations/presentation/screens/conversations_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/web_image.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'firebase_chat_screen.dart';
import '../widgets/delete_conversation_dialog.dart';
import '../../data/services/conversation_service.dart';

class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends ConsumerState<ConversationsListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ConversationService _conversationService = ConversationService();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Bilet ara butonu
          IconButton(
            onPressed: () {
              // Ana sayfaya geri dön ve bilet ara tab'ını aç
              Navigator.of(context).pop();
              // Ana sayfa context'ine mesaj gönder
            },
            icon: const Icon(Icons.search),
            tooltip: 'Bilet Ara',
          ),
        ],
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Mesajları görmek için giriş yapın'),
            );
          }

          return StreamBuilder<List<Conversation>>(
            stream: _getConversationsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text('Mesajlar yüklenirken hata oluştu'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                );
              }

              final conversations = snapshot.data ?? [];

              if (conversations.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return _buildConversationTile(context, conversation, user.uid);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Hata: $error'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz mesajınız yok',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bilet sahipleriyle mesajlaşmaya başlayın',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.search),
            label: const Text('Bilet Ara'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, Conversation conversation, String currentUserId) {
    final theme = Theme.of(context);
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => conversation.participants.first,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: otherParticipant.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    webSafeImageUrl(otherParticipant.avatarUrl!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
        ),
        title: Text(
          otherParticipant.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          conversation.lastMessage?.content ?? 'Mesaj yok',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conversation.lastMessage?.createdAt ?? conversation.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteDialog(context, conversation, otherParticipant.name);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sil'),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FirebaseChatScreen(
                conversationId: conversation.id,
                otherUserId: otherParticipant.id,
                otherUserName: otherParticipant.name,
                otherUserAvatarUrl: otherParticipant.avatarUrl,
              ),
            ),
          );
        },
      ),
    );
  }

  Stream<List<Conversation>> _getConversationsStream(String userId) {
    return _firebaseService.conversations
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true) // Sadece aktif conversation'lar
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <Conversation>[];
      }

      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Participants listesini parse et
          final participantsList = (data['participants'] as List<dynamic>?)
              ?.cast<String>() ?? <String>[];
          
          final participants = participantsList.map((id) {
            return ConversationParticipant(
              id: id,
              name: id == userId ? 'Sen' : 'Kullanıcı',
              avatarUrl: null,
            );
          }).toList();

          return Conversation(
            id: doc.id,
            participants: participants,
            lastMessage: data['lastMessage'] != null
                ? ConversationMessage(
                    id: data['lastMessage']['id'] as String? ?? '',
                    content: data['lastMessage']['content'] as String? ?? '',
                    senderId: data['lastMessage']['senderId'] as String? ?? '',
                    createdAt: data['lastMessage']['createdAt'] != null
                        ? (data['lastMessage']['createdAt'] is int
                            ? DateTime.fromMillisecondsSinceEpoch(
                                data['lastMessage']['createdAt'])
                            : DateTime.now())
                        : DateTime.now(),
                  )
                : null,
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] is int
                    ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
                    : DateTime.now())
                : DateTime.now(),
            unreadCount: data['unreadCount_$userId'] ?? 0,
          );
        } catch (e) {
          // Hata durumunda boş conversation dön
          return Conversation(
            id: doc.id,
            participants: [ConversationParticipant(
              id: userId,
              name: 'Sen',
              avatarUrl: null,
            )],
            createdAt: DateTime.now(),
            unreadCount: 0,
          );
        }
      }).toList();
    }).handleError((error) {
      return <Conversation>[];
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}dk';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}sa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Silme dialog'unu göster
  void _showDeleteDialog(BuildContext context, Conversation conversation, String participantName) {
    DeleteConversationDialog.show(
      context,
      conversationTitle: participantName,
      onConfirm: () => _deleteConversation(conversation.id),
    );
  }

  /// Conversation'ı sil
  Future<void> _deleteConversation(String conversationId) async {
    try {
      // Loading göster
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Conversation'ı sil
      final success = await _conversationService.deleteConversation(conversationId);

      // Loading'i kapat
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        // Başarı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sohbet başarıyla silindi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Hata mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sohbet silinirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Loading'i kapat
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Conversation entity'leri
class Conversation {
  final String id;
  final List<ConversationParticipant> participants;
  final ConversationMessage? lastMessage;
  final DateTime createdAt;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    this.unreadCount = 0,
  });
}

class ConversationParticipant {
  final String id;
  final String name;
  final String? avatarUrl;

  ConversationParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
  });
}

class ConversationMessage {
  final String id;
  final String content;
  final String senderId;
  final DateTime createdAt;

  ConversationMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
  });
}
