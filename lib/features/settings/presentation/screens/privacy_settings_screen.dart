import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  // Gizlilik ayarları state'leri
  bool _profileVisibility = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _allowMessageRequests = true;
  bool _shareLocationData = false;
  bool _personalizedAds = false;
  bool _dataAnalytics = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacy),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Profil Gizliliği
          _buildSection(
            title: 'Profil Gizliliği',
            children: [
              SwitchListTile(
                title: const Text('Profilim herkese açık'),
                subtitle: const Text('Diğer kullanıcılar profilinizi görebilir'),
                value: _profileVisibility,
                onChanged: (value) {
                  setState(() {
                    _profileVisibility = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Çevrimiçi durumumu göster'),
                subtitle: const Text('Aktif olduğunuzda yeşil nokta görünür'),
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() {
                    _showOnlineStatus = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Son görülme zamanını göster'),
                subtitle: const Text('En son ne zaman aktif olduğunuz görünsün'),
                value: _showLastSeen,
                onChanged: (value) {
                  setState(() {
                    _showLastSeen = value;
                  });
                },
              ),
            ],
          ),

          const Divider(height: 32),

          // Mesajlaşma Gizliliği
          _buildSection(
            title: 'Mesajlaşma',
            children: [
              SwitchListTile(
                title: const Text('Mesaj isteklerini kabul et'),
                subtitle: const Text('Tanımadığınız kişilerden mesaj alabilirsiniz'),
                value: _allowMessageRequests,
                onChanged: (value) {
                  setState(() {
                    _allowMessageRequests = value;
                  });
                },
              ),
              ListTile(
                title: const Text('Engellenen kullanıcılar'),
                subtitle: const Text('Engellediğiniz kullanıcıları yönetin'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Engellenen kullanıcılar sayfasına git
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Engellenen kullanıcılar sayfası yakında eklenecek'),
                    ),
                  );
                },
              ),
            ],
          ),

          const Divider(height: 32),

          // Veri ve İzinler
          _buildSection(
            title: 'Veri ve İzinler',
            children: [
              SwitchListTile(
                title: const Text('Konum verilerini paylaş'),
                subtitle: const Text('Yakınızdaki etkinlikleri göstermek için'),
                value: _shareLocationData,
                onChanged: (value) {
                  setState(() {
                    _shareLocationData = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Kişiselleştirilmiş reklamlar'),
                subtitle: const Text('İlgi alanlarınıza göre reklamlar gösterilir'),
                value: _personalizedAds,
                onChanged: (value) {
                  setState(() {
                    _personalizedAds = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Kullanım analitikleri'),
                subtitle: const Text('Uygulamayı geliştirmek için anonim veri topla'),
                value: _dataAnalytics,
                onChanged: (value) {
                  setState(() {
                    _dataAnalytics = value;
                  });
                },
              ),
            ],
          ),

          const Divider(height: 32),

          // Hesap İşlemleri
          _buildSection(
            title: 'Hesap İşlemleri',
            children: [
              ListTile(
                title: const Text('Verilerimi indir'),
                subtitle: const Text('Tüm verilerinizi indirin'),
                leading: const Icon(Icons.download),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showDataDownloadDialog(context);
                },
              ),
              ListTile(
                title: const Text('Hesabımı geçici olarak dondur'),
                subtitle: const Text('Hesabınız geçici olarak devre dışı bırakılır'),
                leading: const Icon(Icons.pause_circle_outline),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showFreezeAccountDialog(context);
                },
              ),
              ListTile(
                title: Text(
                  'Hesabımı kalıcı olarak sil',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                subtitle: const Text('Bu işlem geri alınamaz'),
                leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _showDataDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verilerimi İndir'),
        content: const Text(
          'Verileriniz hazırlandığında e-posta adresinize gönderilecektir. Bu işlem 24 saate kadar sürebilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veri indirme talebiniz alındı'),
                ),
              );
            },
            child: const Text('İndir'),
          ),
        ],
      ),
    );
  }

  void _showFreezeAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Dondur'),
        content: const Text(
          'Hesabınız geçici olarak dondurulacak. İstediğiniz zaman tekrar giriş yaparak hesabınızı aktif edebilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Hesap dondurma işlemi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hesap dondurma özelliği yakında eklenecek'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Dondur'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hesabı Kalıcı Olarak Sil',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        content: const Text(
          'Bu işlem geri alınamaz! Tüm verileriniz, mesajlarınız ve biletleriniz kalıcı olarak silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: Hesap silme işlemi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hesap silme özelliği yakında eklenecek'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Kalıcı Olarak Sil'),
          ),
        ],
      ),
    );
  }
}
