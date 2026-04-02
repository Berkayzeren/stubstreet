// lib/features/conversations/presentation/screens/firebase_chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/firebase_chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../../domain/entities/message.dart';
import '../../../auth/presentation/screens/advanced_profile_screen.dart';
import '../../../../core/utils/memory_optimizer.dart';

/// Firebase tabanlı gelişmiş chat ekranı
/// 
/// Bu ekran, iki kullanıcı arasındaki gerçek zamanlı mesajlaşmayı sağlar.
/// Özellikler:
/// - Gerçek zamanlı mesaj alış-verişi
/// - Kullanıcı çevrimiçi/çevrimdışı durumu
/// - Mesaj gönderme durumu
/// - Otomatik scroll ve mesaj okundu işaretleme
class FirebaseChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;

  const FirebaseChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
  });

  @override
  ConsumerState<FirebaseChatScreen> createState() => _FirebaseChatScreenState();
}

class _FirebaseChatScreenState extends ConsumerState<FirebaseChatScreen>
    with WidgetsBindingObserver, MemoryOptimizedMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Memory optimization için controller'ları kaydet
    registerController(_messageController);
    registerController(_scrollController);
    
    // Chat ekranı başlatıldı
    
    // Ekran açıldığında mesajları okundu olarak işaretle ve conversations listesini invalid et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
      try {
        ref.invalidate(userConversationsProvider);
        ref.invalidate(totalUnreadMessagesCountProvider);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingTimer?.cancel();
    // MemoryOptimizedMixin otomatik olarak controller'ları dispose edecek
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Uygulama aktif olduğunda mesajları okundu olarak işaretle
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
      try {
        ref.invalidate(userConversationsProvider);
        ref.invalidate(totalUnreadMessagesCountProvider);
      } catch (_) {}
    }
  }

  /// Mesajları okundu olarak işaretle
  void _markMessagesAsRead() {
    debugPrint('🔍 Mesajlar okundu olarak işaretleniyor: ${widget.conversationId}');
    ref.read(messageSenderProvider.notifier).markAsRead(widget.conversationId);
  }

  /// Mesaj gönder
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    debugPrint('📤 DEBUG: Mesaj gönderilmeye başlanıyor - İçerik: $content, Alıcı: ${widget.otherUserId}');

    // Input'u temizle
    _messageController.clear();
    
    // Typing durumunu sıfırla
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }

    try {
      // Mesajı gönder
      await ref.read(messageSenderProvider.notifier).sendMessage(
        receiverId: widget.otherUserId,
        content: content,
      );

      debugPrint('✅ DEBUG: Mesaj başarıyla gönderildi');

      // Mesaj gönderildikten sonra en alta scroll et
      _scrollToBottom();
      
    } catch (e) {
      debugPrint('❌ DEBUG: Mesaj gönderme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// En alta scroll et
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Typing durumunu güncelle
  void _onTextChanged(String text) {
    // Typing timer'ını sıfırla
    _typingTimer?.cancel();
    
    if (text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
    }

    // 2 saniye sonra typing durumunu kapat
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
    
    // Timer'ı memory optimizer'a kaydet
    if (_typingTimer != null) {
      registerTimer(_typingTimer!);
    }
  }

  /// Tarih separator widget'ı oluştur
  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Bugün';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Dün';
    } else {
      dateText = DateFormat('dd/MM/yyyy').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Mesaj detaylarını göster (gönderilme zamanı, durum vb.)
  void _showMessageDetails(BuildContext context, Message message) {
    final theme = Theme.of(context);
    final isCurrentUser = message.senderId == ref.read(firebaseChatServiceProvider).currentUserId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCurrentUser ? Icons.send : Icons.reply,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isCurrentUser ? 'Gönderilen Mesaj' : 'Alınan Mesaj',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mesaj içeriği
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mesaj bilgileri
            _buildMessageInfo('Gönderilme Zamanı', DateFormat('dd.MM.yyyy HH:mm').format(message.createdAt)),
            const SizedBox(height: 8),
            _buildMessageInfo('Durum', _getMessageStatusText(message.status)),
            if (!isCurrentUser) ...[
              const SizedBox(height: 8),
              _buildMessageInfo('Gönderen', widget.otherUserName),
            ],
            const SizedBox(height: 8),
            _buildMessageInfo('Mesaj ID', message.id),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
          if (isCurrentUser)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteMessageDialog(context, message);
              },
              child: Text(
                'Sil',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  /// Mesaj bilgi satırı oluştur
  Widget _buildMessageInfo(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  /// Mesaj durumu metnini getir
  String _getMessageStatusText(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return 'Gönderildi ✓';
      case MessageStatus.delivered:
        return 'İletildi ✓✓';
      case MessageStatus.read:
        return 'Okundu ✓✓';
      case MessageStatus.failed:
        return 'Gönderilemedi ❌';
    }
  }

  /// Mesaj silme onayı göster
  void _showDeleteMessageDialog(BuildContext context, Message message) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Mesajı Sil'),
          ],
        ),
        content: const Text('Bu mesaj sadece sizde gizlenecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMessage(message);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Bende Sil'),
          ),
        ],
      ),
    );
  }

  /// Mesajı yalnızca mevcut kullanıcı için gizle
  Future<void> _deleteMessage(Message message) async {
    try {
      final chatService = ref.read(firebaseChatServiceProvider);
      await FirebaseFirestore.instance.collection('messages').doc(message.id).update({
        'deletedFor': FieldValue.arrayUnion([chatService.currentUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj sizde gizlendi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gizlenemedi: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Kullanıcı durumunu dinle
    final userPresenceAsync = ref.watch(userPresenceProvider(widget.otherUserId));
    
    // Mesajları dinle
    final messagesAsync = ref.watch(conversationMessagesProvider(widget.conversationId));
    
    // Mesaj gönderme durumunu dinle
    final messageSendingState = ref.watch(messageSenderProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true, // Keyboard awareness için
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AdvancedProfileScreen(
                  userId: widget.otherUserId,
                ),
              ),
            );
          },
          child: Row(
            children: [
              // Profil avatarı
              CircleAvatar(
                radius: 16,
                backgroundColor: widget.otherUserAvatarUrl != null && widget.otherUserAvatarUrl!.isNotEmpty
                    ? Colors.transparent
                    : theme.colorScheme.primary,
                foregroundImage: widget.otherUserAvatarUrl != null && widget.otherUserAvatarUrl!.isNotEmpty
                    ? NetworkImage(widget.otherUserAvatarUrl!)
                    : null,
                child: (widget.otherUserAvatarUrl == null || widget.otherUserAvatarUrl!.isEmpty)
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              // Kullanıcı adı ve durumu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    userPresenceAsync.when(
                      data: (presence) {
                        final isOnline = presence?['isOnline'] == true;
                        final lastSeen = presence?['lastSeen'] as Timestamp?;

                        if (isOnline) {
                          return Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Çevrimiçi',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        } else if (lastSeen != null) {
                          final lastSeenDate = lastSeen.toDate();
                          final now = DateTime.now();
                          final difference = now.difference(lastSeenDate);

                          String lastSeenText;
                          if (difference.inMinutes < 1) {
                            lastSeenText = 'Az önce görüldü';
                          } else if (difference.inHours < 1) {
                            lastSeenText = '${difference.inMinutes} dk önce görüldü';
                          } else if (difference.inDays < 1) {
                            lastSeenText = '${difference.inHours} sa önce görüldü';
                          } else {
                            lastSeenText = DateFormat('dd/MM/yyyy').format(lastSeenDate);
                          }

                          return Text(
                            lastSeenText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          );
                        } else {
                          return Text(
                            'Çevrimdışı',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          );
                        }
                      },
                      loading: () => Text(
                        'Durum yükleniyor...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 1,
      ),
      
      body: Column(
        children: [
          // Mesaj listesi
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // Yeni mesajlar yüklendiğinde okunmamışları sıfırla ve rozeti güncelle
                _markMessagesAsRead();
                try {
                  ref.invalidate(userConversationsProvider);
                  ref.invalidate(totalUnreadMessagesCountProvider);
                } catch (_) {}
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlk mesajınızı gönderin!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Mesajları tarihe göre grupla
                final groupedMessages = <String, List<Message>>{};
                for (final message in messages) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(message.createdAt);
                  groupedMessages.putIfAbsent(dateKey, () => []).add(message);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: groupedMessages.length,
                  itemBuilder: (context, groupIndex) {
                    final dateKey = groupedMessages.keys.elementAt(groupIndex);
                    final dayMessages = groupedMessages[dateKey]!;
                    final groupDate = DateTime.parse(dateKey);

                    return Column(
                      children: [
                        // Tarih separator'ı
                        _buildDateSeparator(groupDate),
                        
                        // O günün mesajları
                        ...dayMessages.map((message) {
                          final isCurrentUser = message.senderId == ref.read(firebaseChatServiceProvider).currentUserId;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: MessageBubble(
                              message: message,
                              isCurrentUser: isCurrentUser,
                              senderProfileImageUrl: message.senderId == widget.otherUserId
                                  ? widget.otherUserAvatarUrl
                                  : ((ref.read(firebaseChatServiceProvider).currentUserProfilePhoto?.isNotEmpty ?? false)
                                      ? ref.read(firebaseChatServiceProvider).currentUserProfilePhoto
                                      : null),
                              senderDisplayName: message.senderId == widget.otherUserId
                                  ? widget.otherUserName
                                  : ref.read(firebaseChatServiceProvider).currentUserDisplayName,
                              showTimeStamp: true,
                              onMessageTap: (msg) {
                                // Mesaj detaylarını göster
                                _showMessageDetails(context, msg);
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
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
                      'Mesajlar yüklenemedi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Mesaj gönderme alanı
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    // Mesaj input alanı
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: _messageController,
                          onChanged: _onTextChanged,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Mesaj yazın...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Gönder butonu
                    messageSendingState.when(
                      data: (_) => Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _sendMessage,
                          child: Ink(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.send_rounded,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(
                          Icons.error,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
