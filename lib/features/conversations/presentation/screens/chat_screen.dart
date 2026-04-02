// lib/features/conversations/presentation/screens/chat_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/real_time_providers.dart' as realtime;
import '../providers/chat_moderation_providers.dart';
import '../providers/firebase_chat_providers.dart' as firebase;

import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String otherUserId;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserId,
    required this.currentUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    // Join conversation room when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(realtime.realTimeServiceProvider);
      service.joinConversation(widget.conversationId, widget.currentUserId);
      // Mark messages as read when opening conversation
      _markMessagesAsRead();
    });
  }

  /// Mark messages as read
  void _markMessagesAsRead() {
    // Use Firebase Chat Service to mark messages as read
    final chatService = ref.read(firebase.firebaseChatServiceProvider);
    chatService.markMessagesAsRead(widget.conversationId);
  }

  @override
  void dispose() {
    // Cancel typing timer first
    _typingTimer?.cancel();

    // Dispose controllers
    _messageController.dispose();
    _scrollController.dispose();

    // Leave conversation room when screen closes
    // Check if ref is still available before using it
    try {
      final service = ref.read(realtime.realTimeServiceProvider);
      service.leaveConversation(widget.conversationId);
    } catch (e) {
      // Ignore errors during disposal
      debugPrint('Error during disposal: $e');
    }

    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      // Stop typing indicator
      ref
          .read(realtime.typingIndicatorProvider.notifier)
          .stopTyping(widget.conversationId, widget.currentUserId);

      // Get receiver ID from conversation participants
      String receiverId = 'unknown_user';
      try {
        final conversationDoc = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .get();
        
        if (conversationDoc.exists) {
          final participants = List<String>.from(conversationDoc.data()?['participants'] ?? []);
          receiverId = participants.firstWhere(
            (id) => id != widget.currentUserId,
            orElse: () => 'unknown_user',
          );
        }
      } catch (e) {
        debugPrint('Error getting receiver ID: $e');
      }

      // Send message using the provider
      await ref
          .read(realtime.messageSenderProvider.notifier)
          .sendMessage(
            conversationId: widget.conversationId,
            senderId: widget.currentUserId,
            receiverId: receiverId,
            content: messageText,
          );

      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
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

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      // Start typing indicator
      ref
          .read(realtime.typingIndicatorProvider.notifier)
          .startTyping(widget.conversationId, widget.currentUserId);

      // Reset typing timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        ref
            .read(realtime.typingIndicatorProvider.notifier)
            .stopTyping(widget.conversationId, widget.currentUserId);
      });
    }
  }

  // Şikayet dialog'unu göster
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedReason;
        final TextEditingController detailsController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Şikayet Et'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lütfen şikayet nedeninizi seçin:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    // Şikayet nedenleri
                    RadioListTile<String>(
                      title: const Text('Spam veya sahte hesap'),
                      value: 'spam',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                    ),
                    RadioListTile<String>(
                      title: const Text('Uygunsuz içerik'),
                      value: 'inappropriate',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                    ),
                    RadioListTile<String>(
                      title: const Text('Taciz veya zorbalık'),
                      value: 'harassment',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                    ),
                    RadioListTile<String>(
                      title: const Text('Dolandırıcılık'),
                      value: 'fraud',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                    ),
                    RadioListTile<String>(
                      title: const Text('Diğer'),
                      value: 'other',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      decoration: const InputDecoration(
                        labelText: 'Ek detaylar (opsiyonel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          
                          try {
                            await ref.read(reportUserProvider.notifier).reportUser(
                              reportedUserId: widget.otherUserId,
                              reason: selectedReason!,
                              details: detailsController.text.trim().isNotEmpty 
                                  ? detailsController.text.trim() 
                                  : null,
                            );
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Şikayetiniz alındı ve incelenecek'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Şikayet gönderilemedi: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text('Şikayet Et'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Engelleme dialog'unu göster
  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kullanıcıyı Engelle'),
          content: Text(
            '${widget.otherUserName} kullanıcısını engellemek istediğinizden emin misiniz?\n\n'
            'Engellediğiniz kullanıcılar size mesaj gönderemez ve biletlerinizi göremez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  await ref.read(blockUserProvider.notifier).blockUser(widget.otherUserId);
                  
                  if (mounted) {
                    Navigator.of(context).pop(); // Chat ekranını kapat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kullanıcı engellendi'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Engelleme işlemi başarısız: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Engelle'),
            ),
          ],
        );
      },
    );
  }

  // Sohbeti temizleme dialog'unu göster
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sohbeti Temizle'),
          content: const Text(
            'Tüm mesajlar silinecek. Bu işlem geri alınamaz.\n\n'
            'Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  await ref.read(clearChatHistoryProvider.notifier).clearChat(widget.otherUserId);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sohbet temizlendi'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sohbet temizleme başarısız: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Temizle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messageSenderState = ref.watch(realtime.messageSenderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Hide connection status - show only typing indicator
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Menü seçimine göre işlem yap
              switch (value) {
                case 'report':
                  _showReportDialog();
                  break;
                case 'block':
                  _showBlockDialog();
                  break;
                case 'clear':
                  _showClearChatDialog();
                  break;
              }
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Şikayet Et'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Engelle'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('Sohbeti Temizle'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: ref
                  .watch(realtime.conversationMessagesProvider(widget.conversationId))
                  .when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz mesaj yok',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'İlk mesajınızı gönderin!',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser =
                              message.senderId == widget.currentUserId;

                          return MessageBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Hata: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(
                                realtime.conversationMessagesProvider(
                                  widget.conversationId,
                                ),
                              );
                            },
                            child: const Text('Tekrar Dene'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  onPressed: () {
                    // TODO: Implement file attachment
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.featureComingSoon),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: Icon(Icons.attach_file, color: AppTheme.primaryColor),
                ),

                // Message input field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Mesaj yazın...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _onTextChanged,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: messageSenderState.isLoading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: messageSenderState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  // Dummy data for testing - replace with real Firestore stream
}
