// lib/features/conversations/presentation/screens/firebase_conversations_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../providers/firebase_chat_providers.dart';
import '../../../../core/services/firebase_chat_service.dart';
import '../providers/message_sender_provider.dart' as sender_provider;
import '../../../auth/presentation/providers/auth_providers.dart';
import 'firebase_chat_screen.dart';
import '../../../auth/presentation/screens/advanced_profile_screen.dart';
import '../../domain/entities/conversation.dart';
import '../../../../core/mixins/scroll_to_top_mixin.dart';

/// Basit arama metni durumu için provider
final conversationsSearchQueryProvider = StateProvider<String>((ref) => '');

/// Firebase tabanlı sohbet listesi ekranı
///
/// Bu ekran, kullanıcının tüm aktif sohbetlerini gösterir
/// ve gerçek zamanlı güncellemeler sağlar.
class FirebaseConversationsListScreen extends ConsumerStatefulWidget {
  const FirebaseConversationsListScreen({super.key});

  @override
  ConsumerState<FirebaseConversationsListScreen> createState() =>
      _FirebaseConversationsListScreenState();
}

class _FirebaseConversationsListScreenState
    extends ConsumerState<FirebaseConversationsListScreen>
    with ScrollToTopMixin {
  /// Boş durum widget'ı oluştur
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz mesajınız yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Bilet satın aldığınızda veya sattığınızda\nsatıcı/alıcı ile mesajlaşabilirsiniz.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Ana sayfaya geri dön ve bilet ara tab'ına git
                Navigator.of(context).popUntil((route) => route.isFirst);
                // Home screen'de index değiştirmek için Navigator state kullan
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                  arguments: {'tabIndex': 1}, // Bilet ara tab'ı
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Bilet Ara'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sohbet tile widget'ı oluştur
  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    String currentUserId,
  ) {
    final theme = Theme.of(context);

    // Karşı taraftaki kullanıcının ID'sini bul
    final otherUserId = conversation.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, child) {
        // Karşı kullanıcının durumunu dinle
        final userPresenceAsync = ref.watch(userPresenceProvider(otherUserId));

        return userPresenceAsync.when(
          data: (presence) {
            final otherUserName =
                presence?['username'] as String? ?? 'Bilinmeyen Kullanıcı';
            final otherUserAvatarUrl = presence?['profileImageUrl'] as String?;
            final isOnline = presence?['isOnline'] as bool? ?? false;
            final unreadCount = conversation.unreadCount[currentUserId] ?? 0;

            // Avatarı conversation metadata'sına kaydet (gelecekteki kullanımlar için)
            if (otherUserAvatarUrl != null && otherUserAvatarUrl.isNotEmpty) {
              Future.microtask(() {
                ref
                    .read(firebaseChatServiceProvider)
                    .updateParticipantAvatar(
                      conversation.id,
                      otherUserId,
                      otherUserAvatarUrl,
                    )
                    .catchError((_) {});
              });
            }

            return Dismissible(
              key: ValueKey('conv_${conversation.id}'),
              direction: DismissDirection.startToEnd,
              background: Container(
                color: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.delete, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Sil',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              confirmDismiss: (direction) async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sohbeti Gizle'),
                    content: const Text(
                      'Bu sohbet sadece sizde gizlenecek. Diğer kullanıcıda görünmeye devam edecek.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Bende Gizle',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return false;

                try {
                  await ref
                      .read(firebaseChatServiceProvider)
                      .hideConversationForCurrentUser(conversation.id);
                  if (!mounted) return false;
                  try {
                    ref.invalidate(userConversationsProvider);
                    ref.invalidate(totalUnreadMessagesCountProvider);
                  } catch (_) {}
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Sohbet sizde gizlendi')),
                  );
                  return true;
                } catch (e) {
                  if (!mounted) return false;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Sohbet gizlenemedi: $e')),
                  );
                  return false;
                }
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  // Profil avatarı
                  leading: Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AdvancedProfileScreen(userId: otherUserId),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundImage:
                              (otherUserAvatarUrl != null &&
                                  otherUserAvatarUrl.isNotEmpty)
                              ? NetworkImage(otherUserAvatarUrl)
                              : null,
                          child:
                              (otherUserAvatarUrl == null ||
                                  otherUserAvatarUrl.isEmpty)
                              ? Text(
                                  otherUserName.isNotEmpty
                                      ? otherUserName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),

                      // Online durumu göstergesi
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Kullanıcı adı ve son mesaj
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Kullanıcı online/offline ve son mesaj tarihi
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Online durumu
                          Text(
                            isOnline ? 'Çevrimiçi' : _getLastSeenText(presence),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isOnline
                                  ? Colors.green
                                  : Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: isOnline
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),

                          // Son mesaj tarihi
                          if (conversation.lastMessageTime != null)
                            Text(
                              _formatMessageTime(conversation.lastMessageTime!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Son mesaj ve online durumu
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // Son mesaj
                      if (conversation.lastMessage != null)
                        Text(
                          conversation.lastMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: unreadCount > 0
                                ? theme.colorScheme.onSurface
                                : Colors.grey.shade600,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text(
                          'Sohbet başlatın...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                      const SizedBox(height: 2),

                      // Online durumu metni
                      Text(
                        isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOnline ? Colors.green : Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // Okunmamış mesaj sayısı
                  trailing: unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,

                  // Sohbete git
                  onTap: () async {
                    // Context'i async işlemden önce sakla
                    final navigator = Navigator.of(context);

                    // Rozeti sıfırla ve UI'ı tazele
                    await ref
                        .read(sender_provider.messageSenderProvider.notifier)
                        .markAsRead(conversation.id);

                    if (!mounted) return;
                    await navigator.push(
                      MaterialPageRoute(
                        builder: (context) => FirebaseChatScreen(
                          conversationId: conversation.id,
                          otherUserId: otherUserId,
                          otherUserName: otherUserName,
                          otherUserAvatarUrl: otherUserAvatarUrl,
                        ),
                      ),
                    );
                    if (!mounted) return;

                    // Geri dönüldüğünde liste ve toplam rozet sayısını invalid et
                    try {
                      ref.invalidate(userConversationsProvider);
                      ref.invalidate(totalUnreadMessagesCountProvider);
                    } catch (_) {}
                  },
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ),
          error: (error, stackTrace) {
            debugPrint('🔥 Kullanıcı durumu yüklenemedi: $error');
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  /// Mesaj zamanını formatla
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Bugün - saat formatı
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Dün
      return 'Dün';
    } else if (difference.inDays < 7) {
      // Bu hafta - gün adı
      return DateFormat('EEEE', 'tr_TR').format(dateTime);
    } else {
      // Daha eski - tarih
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Auth durumunu kontrol et
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: null,
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Mesajları görmek için giriş yapın',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Kullanıcının sohbetlerini dinle
          final conversationsAsync = ref.watch(userConversationsProvider);

          // DEBUG: Mesajlaşma durumunu logla
          debugPrint('🔍 DEBUG: Mesajlaşma durumu - User: ${user.uid}');

          return conversationsAsync.when(
            data: (conversations) {
              debugPrint(
                '✅ DEBUG: Sohbetler yüklendi - Sayı: ${conversations.length}',
              );
              if (conversations.isEmpty) {
                debugPrint('📭 DEBUG: Hiç sohbet yok - Boş durum gösteriliyor');
                return _buildEmptyState(context);
              }

              return Column(
                children: [
                  // Gövde-içi arama alanı
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Sohbetleri ara',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (q) {
                        // Arama metnini global state'e yaz
                        ref
                                .read(conversationsSearchQueryProvider.notifier)
                                .state =
                            q;
                      },
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final q = ref
                            .watch(conversationsSearchQueryProvider)
                            .trim()
                            .toLowerCase();
                        final filtered = q.isEmpty
                            ? conversations
                            : conversations.where((c) {
                                final last = (c.lastMessage ?? '')
                                    .toLowerCase();
                                final ticketTitle =
                                    (c.metadata != null
                                            ? (c.metadata!['ticketTitle']
                                                      ?.toString() ??
                                                  '')
                                            : '')
                                        .toLowerCase();
                                return last.contains(q) ||
                                    ticketTitle.contains(q) ||
                                    c.id.toLowerCase().contains(q);
                              }).toList();

                        if (filtered.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(child: Text('Sonuç bulunamadı')),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final conversation = filtered[index];
                            return _buildConversationTile(
                              context,
                              conversation,
                              user.uid,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () {
              debugPrint('⏳ DEBUG: Sohbetler yükleniyor...');
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stack) {
              debugPrint('❌ DEBUG: Sohbet yükleme hatası: $error');
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sohbetler yüklenemedi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(userConversationsProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Auth hatası: $error')),
      ),
    );
  }

  /// Son görülme zamanını formatla
  String _getLastSeenText(Map<String, dynamic>? presence) {
    if (presence == null) return 'Son görülme bilinmiyor';

    final lastSeen = presence['lastSeen'] as Timestamp?;
    if (lastSeen == null) return 'Son görülme bilinmiyor';

    final lastSeenDate = lastSeen.toDate();
    final now = DateTime.now();
    final difference = now.difference(lastSeenDate);

    if (difference.inMinutes < 1) {
      return 'Az önce çevrimiçiydi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return 'Uzun zaman önce';
    }
  }
}
