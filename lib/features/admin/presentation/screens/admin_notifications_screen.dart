// lib/features/admin/presentation/screens/admin_notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_api_service.dart';
import '../../../../core/providers/admin_provider.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _userIdsController = TextEditingController();
  
  String _selectedType = 'general';
  bool _isLoading = false;
  
  final List<String> _notificationTypes = [
    'general',
    'announcement',
    'marketing',
    'system',
    'promotion',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _userIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = ref.watch(isAdminProvider);
    final isAdminLoading = ref.watch(isAdminLoadingProvider);

    // Admin kontrolü
    if (isAdminLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erişim Engellendi'),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Bu sayfaya erişim yetkiniz yok',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sadece admin kullanıcılar bu panele erişebilir',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Bildirim Gönder'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hızlı Eylemler
            _buildQuickActions(context),
            
            const SizedBox(height: 24),
            
            // Manuel Bildirim Formu
            _buildManualNotificationForm(context),
            
            const SizedBox(height: 24),
            
            // Gönder Butonu
            _buildSendButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hızlı Eylemler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionChip(
                  'Tüm Kullanıcılara Duyuru',
                  Icons.campaign,
                  () => _showAnnouncementDialog(context),
                ),
                _buildQuickActionChip(
                  'Satıcılara Bildirim',
                  Icons.store,
                  () => _showCategoryNotificationDialog(context, 'sellers'),
                ),
                _buildQuickActionChip(
                  'Alıcılara Bildirim',
                  Icons.shopping_cart,
                  () => _showCategoryNotificationDialog(context, 'buyers'),
                ),
                _buildQuickActionChip(
                  'Premium Kullanıcılara',
                  Icons.star,
                  () => _showCategoryNotificationDialog(context, 'premium'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _buildManualNotificationForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manuel Bildirim Gönder',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Bildirim Türü
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Bildirim Türü',
                border: OutlineInputBorder(),
              ),
              items: _notificationTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeDisplayName(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Kullanıcı ID'leri
            TextFormField(
              controller: _userIdsController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı ID\'leri (virgülle ayırın)',
                hintText: 'user1,user2,user3 veya "all" tüm kullanıcılar için',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Başlık
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Bildirim Başlığı',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            
            const SizedBox(height: 16),
            
            // İçerik
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Bildirim İçeriği',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendManualNotification,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Bildirim Gönder'),
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'general':
        return 'Genel';
      case 'announcement':
        return 'Duyuru';
      case 'marketing':
        return 'Pazarlama';
      case 'system':
        return 'Sistem';
      case 'promotion':
        return 'Promosyon';
      default:
        return type;
    }
  }

  void _showAnnouncementDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Kullanıcılara Duyuru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Duyuru Başlığı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Duyuru İçeriği',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                Navigator.pop(context);
                await _sendAnnouncement(titleController.text, bodyController.text);
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showCategoryNotificationDialog(BuildContext context, String category) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final categoryNames = {
      'sellers': 'Satıcılar',
      'buyers': 'Alıcılar',
      'premium': 'Premium Kullanıcılar',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${categoryNames[category]} için Bildirim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Bildirim Başlığı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Bildirim İçeriği',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                Navigator.pop(context);
                await _sendCategoryNotification(
                  category,
                  titleController.text,
                  bodyController.text,
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendManualNotification() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      _showErrorSnackBar('Başlık ve içerik alanları zorunludur');
      return;
    }

    if (_userIdsController.text.isEmpty) {
      _showErrorSnackBar('En az bir kullanıcı ID\'si giriniz');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userIds = _userIdsController.text
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();

      final result = await NotificationApiService.sendManualNotification(
        userIds: userIds,
        title: _titleController.text,
        body: _bodyController.text,
        type: _selectedType,
      );

      if (result.success) {
        _showSuccessSnackBar(result.message);
        _clearForm();
      } else {
        _showErrorSnackBar(result.error ?? 'Bilinmeyen hata');
      }
    } catch (e) {
      _showErrorSnackBar('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendAnnouncement(String title, String body) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await NotificationApiService.sendAnnouncementToAll(
        title: title,
        body: body,
      );

      if (result.success) {
        _showSuccessSnackBar(result.message);
      } else {
        _showErrorSnackBar(result.error ?? 'Bilinmeyen hata');
      }
    } catch (e) {
      _showErrorSnackBar('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendCategoryNotification(String category, String title, String body) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await NotificationApiService.sendNotificationToCategory(
        category: category,
        title: title,
        body: body,
      );

      if (result.success) {
        _showSuccessSnackBar(result.message);
      } else {
        _showErrorSnackBar(result.error ?? 'Bilinmeyen hata');
      }
    } catch (e) {
      _showErrorSnackBar('Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    _userIdsController.clear();
    setState(() {
      _selectedType = 'general';
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
