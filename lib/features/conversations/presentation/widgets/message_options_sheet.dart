// lib/features/conversations/presentation/widgets/message_options_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/message.dart';
import '../../../../core/services/user_moderation_service.dart';

class MessageOptionsSheet extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final Function(Message message)? onForwardMessage;
  final Function(Message message, String newContent)? onEditMessage;
  final Function(Message message)? onDeleteMessage;
  final VoidCallback? onEditStart;

  const MessageOptionsSheet({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onForwardMessage,
    this.onEditMessage,
    this.onDeleteMessage,
    this.onEditStart,
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
          if (isCurrentUser) ...[
            _buildOptionTile(
              icon: Icons.edit,
              title: 'Edit',
              onTap: () {
                Navigator.pop(context);
                onEditStart?.call();
              },
            ),
            _buildOptionTile(
              icon: Icons.delete,
              title: 'Delete',
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
              isDestructive: true,
            ),
          ],
          _buildOptionTile(
            icon: Icons.forward,
            title: 'Forward',
            onTap: () {
              Navigator.pop(context);
              onForwardMessage?.call(message);
            },
          ),
          if (!isCurrentUser) ...[
            _buildOptionTile(
              icon: Icons.report,
              title: 'Report',
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(context);
              },
              isDestructive: true,
            ),
            _buildOptionTile(
              icon: Icons.block,
              title: 'Block User',
              onTap: () {
                Navigator.pop(context);
                _showBlockDialog(context);
              },
              isDestructive: true,
            ),
          ],
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
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.blue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteMessage?.call(message);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    String selectedReason = '';
    String customReason = '';
    final customReasonController = TextEditingController();
    
    final reasons = [
      'Spam veya istenmeyen içerik',
      'Taciz veya zorbalık',
      'Sahte profil',
      'Uygunsuz içerik',
      'Dolandırıcılık',
      'Telif hakkı ihlali',
      'Diğer',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kullanıcıyı Rapor Et'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu kullanıcıyı neden raporluyorsunuz?',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                
                // Sebep seçenekleri
                ...reasons.map((reason) {
                  return ListTile(
                    leading: Radio<String>(
                      value: reason,
                      // ignore: deprecated_member_use
                      groupValue: selectedReason,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value ?? '';
                        });
                      },
                    ),
                    title: Text(reason),
                    onTap: () {
                      setState(() {
                        selectedReason = reason;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                
                // Özel sebep alanı
                if (selectedReason == 'Diğer') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: customReasonController,
                    decoration: const InputDecoration(
                      labelText: 'Lütfen açıklayın',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      customReason = value;
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: selectedReason.isNotEmpty &&
                      (selectedReason != 'Diğer' || customReason.isNotEmpty)
                  ? () {
                      Navigator.pop(context);
                      _reportUser(context, selectedReason, customReason.isNotEmpty ? customReason : null);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rapor Et'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Engelle'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu kullanıcıyı engellemek istediğinizden emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '• Bu kullanıcıdan mesaj alamayacaksınız',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              '• Bu kullanıcının gönderilerini görmeyeceksiniz',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              '• Bu kullanıcı sizi bulamayacak',
              style: TextStyle(color: Colors.grey),
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
              _blockUser(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Engelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportUser(BuildContext context, String reason, String? customReason) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Rapor gönderiliyor...'),
            ],
          ),
        ),
      );

      await UserModerationService.reportUser(
        reportedUserId: message.senderId,
        reason: reason,
        customReason: customReason,
        messageId: message.id,
      );

      // Loading'i kapat
      if (context.mounted) Navigator.pop(context);

      // Başarı mesajı
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla raporlandı. İnceleme için teşekkürler.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      debugPrint('✅ Kullanıcı başarıyla raporlandı: ${message.senderId}');

    } catch (e) {
      // Loading'i kapat
      if (context.mounted) Navigator.pop(context);

      // Hata mesajı
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor gönderilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint('❌ Kullanıcı raporlama hatası: $e');
    }
  }

  Future<void> _blockUser(BuildContext context) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Kullanıcı engelleniyor...'),
            ],
          ),
        ),
      );

      await UserModerationService.blockUser(message.senderId);

      // Loading'i kapat
      if (context.mounted) Navigator.pop(context);

      // Başarı mesajı
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla engellendi.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      debugPrint('✅ Kullanıcı başarıyla engellendi: ${message.senderId}');

    } catch (e) {
      // Loading'i kapat
      if (context.mounted) Navigator.pop(context);

      // Hata mesajı
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcı engellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      debugPrint('❌ Kullanıcı engelleme hatası: $e');
    }
  }
}
