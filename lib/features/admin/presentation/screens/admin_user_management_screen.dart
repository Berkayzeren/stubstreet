// lib/features/admin/presentation/screens/admin_user_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/admin_provider.dart';
import '../../../../core/services/user_moderation_service.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedReportStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          title: const Text('Kullanıcı Yönetimi'),
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
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.report_problem),
              text: 'Raporlar',
            ),
            Tab(
              icon: Icon(Icons.block),
              text: 'Banlı Kullanıcılar',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'İstatistikler',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildBannedUsersTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Column(
      children: [
        // Filtre seçenekleri
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Durum: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedReportStatus,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Beklemede')),
                    DropdownMenuItem(value: 'reviewed', child: Text('İncelendi')),
                    DropdownMenuItem(value: 'resolved', child: Text('Çözüldü')),
                    DropdownMenuItem(value: 'dismissed', child: Text('Reddedildi')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedReportStatus = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Raporlar listesi
        Expanded(
          child: StreamBuilder<List<UserReport>>(
            stream: UserModerationService.getReports(status: _selectedReportStatus),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Hata: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final reports = snapshot.data ?? [];

              if (reports.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz rapor bulunmuyor',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildReportCard(report);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(UserReport report) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Icon(
                  _getReportStatusIcon(report.status),
                  color: _getReportStatusColor(report.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rapor #${report.id.substring(0, 8)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(_getReportStatusText(report.status)),
                  backgroundColor: _getReportStatusColor(report.status).withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: _getReportStatusColor(report.status),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Rapor detayları
            _buildReportDetailRow('Raporlanan Kullanıcı', report.reportedUserId),
            _buildReportDetailRow('Rapor Eden', report.reporterId),
            _buildReportDetailRow('Sebep', report.reason),
            if (report.customReason != null)
              _buildReportDetailRow('Özel Sebep', report.customReason!),
            if (report.messageId != null)
              _buildReportDetailRow('Mesaj ID', report.messageId!),
            _buildReportDetailRow(
              'Tarih',
              report.createdAt != null
                  ? '${report.createdAt!.day}/${report.createdAt!.month}/${report.createdAt!.year} ${report.createdAt!.hour}:${report.createdAt!.minute.toString().padLeft(2, '0')}'
                  : 'Bilinmiyor',
            ),
            
            if (report.adminNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Notları:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.adminNotes!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Eylem butonları
            if (report.status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReportActionDialog(report),
                      icon: const Icon(Icons.gavel),
                      label: const Text('İncele'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBanUserDialog(report.reportedUserId),
                      icon: const Icon(Icons.block),
                      label: const Text('Banla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReportDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannedUsersTab() {
    return StreamBuilder<List<BannedUser>>(
      stream: UserModerationService.getBannedUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}'),
              ],
            ),
          );
        }

        final bannedUsers = snapshot.data ?? [];

        if (bannedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  'Banlı kullanıcı bulunmuyor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bannedUsers.length,
          itemBuilder: (context, index) {
            final bannedUser = bannedUsers[index];
            return _buildBannedUserCard(bannedUser);
          },
        );
      },
    );
  }

  Widget _buildBannedUserCard(BannedUser bannedUser) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kullanıcı: ${bannedUser.userId}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(bannedUser.isPermanent ? 'Kalıcı' : 'Geçici'),
                  backgroundColor: bannedUser.isPermanent 
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: bannedUser.isPermanent ? Colors.red : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ban detayları
            _buildReportDetailRow('Sebep', bannedUser.reason),
            if (bannedUser.customReason != null)
              _buildReportDetailRow('Özel Sebep', bannedUser.customReason!),
            _buildReportDetailRow('Banlayan', bannedUser.bannedBy),
            _buildReportDetailRow(
              'Ban Tarihi',
              bannedUser.bannedAt != null
                  ? '${bannedUser.bannedAt!.day}/${bannedUser.bannedAt!.month}/${bannedUser.bannedAt!.year}'
                  : 'Bilinmiyor',
            ),
            if (!bannedUser.isPermanent && bannedUser.banUntil != null)
              _buildReportDetailRow(
                'Ban Bitiş',
                '${bannedUser.banUntil!.day}/${bannedUser.banUntil!.month}/${bannedUser.banUntil!.year}',
              ),
            
            const SizedBox(height: 16),
            
            // Eylem butonları
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserDetailsDialog(bannedUser.userId),
                    icon: const Icon(Icons.person),
                    label: const Text('Kullanıcı Detayları'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUnbanUserDialog(bannedUser.userId),
                    icon: const Icon(Icons.check),
                    label: const Text('Ban Kaldır'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moderasyon İstatistikleri',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // İstatistik kartları
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Bekleyen Raporlar',
                          '0', // TODO: Gerçek veri
                          Icons.pending,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Banlı Kullanıcılar',
                          '0', // TODO: Gerçek veri
                          Icons.block,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Bu Ay Çözülen',
                          '0', // TODO: Gerçek veri
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Toplam Rapor',
                          '0', // TODO: Gerçek veri
                          Icons.report,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Yakında eklenecek özellikler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yakında Eklenecek',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Detaylı raporlama grafikleri'),
                  const Text('• Kullanıcı aktivite analizi'),
                  const Text('• Otomatik moderasyon kuralları'),
                  const Text('• Toplu işlem araçları'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper metodlar
  IconData _getReportStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'reviewed':
        return Icons.visibility;
      case 'resolved':
        return Icons.check_circle;
      case 'dismissed':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getReportStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getReportStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Beklemede';
      case 'reviewed':
        return 'İncelendi';
      case 'resolved':
        return 'Çözüldü';
      case 'dismissed':
        return 'Reddedildi';
      default:
        return 'Bilinmiyor';
    }
  }

  // Dialog metodları
  void _showReportActionDialog(UserReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rapor İşlemi'),
        content: const Text('Bu rapor için ne yapmak istiyorsunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReportStatus(report.id, 'dismissed', 'Geçersiz rapor');
            },
            child: const Text('Reddet'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReportStatus(report.id, 'resolved', 'İncelendi ve uygun işlem yapıldı');
            },
            child: const Text('Çözüldü Olarak İşaretle'),
          ),
        ],
      ),
    );
  }

  void _showBanUserDialog(String userId) {
    final reasonController = TextEditingController();
    bool isPermanent = false;
    DateTime? banUntil;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Kullanıcıyı Banla'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Ban Sebebi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Kalıcı Ban'),
                value: isPermanent,
                onChanged: (value) {
                  setState(() {
                    isPermanent = value ?? false;
                    if (isPermanent) banUntil = null;
                  });
                },
              ),
              if (!isPermanent) ...[
                ListTile(
                  title: const Text('Ban Bitiş Tarihi'),
                  subtitle: Text(banUntil != null 
                      ? '${banUntil!.day}/${banUntil!.month}/${banUntil!.year}'
                      : 'Seçilmedi'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        banUntil = date;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: reasonController.text.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _banUser(userId, reasonController.text, banUntil, isPermanent);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Banla'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnbanUserDialog(String userId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban Kaldır'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu kullanıcının banını kaldırmak istediğinizden emin misiniz?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Ban Kaldırma Sebebi (Opsiyonel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              _unbanUser(userId, reasonController.text.isNotEmpty ? reasonController.text : null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ban Kaldır'),
          ),
        ],
      ),
    );
  }

  void _showUserDetailsDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kullanıcı ID: $userId'),
            const SizedBox(height: 8),
            const Text('Bu özellik yakında eklenecek.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // İşlem metodları
  Future<void> _updateReportStatus(String reportId, String status, String adminNotes) async {
    try {
      await UserModerationService.updateReport(
        reportId: reportId,
        status: status,
        adminId: ref.read(adminProvider).toString(), // TODO: Gerçek admin ID
        adminNotes: adminNotes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapor durumu güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _banUser(String userId, String reason, DateTime? banUntil, bool isPermanent) async {
    try {
      await UserModerationService.banUser(
        userId: userId,
        reason: reason,
        banUntil: isPermanent ? null : banUntil,
        adminId: 'admin', // TODO: Gerçek admin ID
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı başarıyla banlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _unbanUser(String userId, String? reason) async {
    try {
      await UserModerationService.unbanUser(
        userId: userId,
        adminId: 'admin', // TODO: Gerçek admin ID
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı banı kaldırıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
