// lib/features/auth/presentation/widgets/settings_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../screens/help_support_screen.dart';

// Inline Privacy & Data Usage screen moved to top-level to avoid nested class errors
class _PrivacyDataUsageScreen extends StatelessWidget {
  const _PrivacyDataUsageScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyDataUsage),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          SettingsBottomSheet._localizedPrivacy(context),
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
    );
  }
}

class SettingsBottomSheet extends ConsumerWidget {
  final ScrollController scrollController;

  const SettingsBottomSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // final themeMode = ref.watch(themeNotifierProvider);
    final notificationPrefs = ref.watch(notificationPreferencesProvider);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Drag handle indicator for intuitive interaction
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white54 : Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header section with title and close button
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.settings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Settings options in a scrollable list
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                // Theme settings section
                _buildSettingsSection(
                  context,
                  AppLocalizations.of(context)!.appearance,
                  [
                    _buildSettingsTile(
                      context,
                      Icons.palette_outlined,
                      AppLocalizations.of(context)!.theme,
                      AppLocalizations.of(context)!.featureComingSoon,
                      onTap: () => _showThemeDialog(context, ref),
                    ),
                    _buildSettingsTile(
                      context,
                      Icons.language_outlined,
                      AppLocalizations.of(context)!.language,
                      '(${ref.read(languageNotifierProvider.notifier).currentLanguageDisplayName})',
                      onTap: () => _showLanguageDialog(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notification settings section
                _buildSettingsSection(
                  context,
                  AppLocalizations.of(context)!.notifications,
                  [
                    _buildSettingsTile(
                      context,
                      Icons.notifications_outlined,
                      AppLocalizations.of(context)!.pushNotifications,
                      AppLocalizations.of(context)!.featureComingSoon,
                      trailing: Switch(
                        value: notificationPrefs.pushNotifications,
                        onChanged: (value) {
                          ref.read(notificationPreferencesProvider.notifier).togglePushNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'Push notifications enabled' : 'Push notifications disabled'),
                              backgroundColor: value ? Colors.green : Colors.orange,
                            ),
                          );
                        },
                      ),
                    ),
                    _buildSettingsTile(
                      context,
                      Icons.email_outlined,
                      AppLocalizations.of(context)!.emailNotifications,
                      AppLocalizations.of(context)!.featureComingSoon,
                      trailing: Switch(
                        value: notificationPrefs.emailNotifications,
                        onChanged: (value) {
                          ref.read(notificationPreferencesProvider.notifier).toggleEmailNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'Email notifications enabled' : 'Email notifications disabled'),
                              backgroundColor: value ? Colors.green : Colors.orange,
                            ),
                          );
                        },
                      ),
                    ),
                    _buildSettingsTile(
                      context,
                      Icons.message_outlined,
                      AppLocalizations.of(context)!.messageNotifications,
                      AppLocalizations.of(context)!.featureComingSoon,
                      trailing: Switch(
                        value: notificationPrefs.messageNotifications,
                        onChanged: (value) {
                          ref.read(notificationPreferencesProvider.notifier).toggleMessageNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'Message notifications enabled' : 'Message notifications disabled'),
                              backgroundColor: value ? Colors.green : Colors.orange,
                            ),
                          );
                        },
                      ),
                    ),
                    _buildSettingsTile(
                      context,
                      Icons.confirmation_number_outlined,
                      AppLocalizations.of(context)!.ticketNotifications,
                      AppLocalizations.of(context)!.featureComingSoon,
                      trailing: Switch(
                        value: notificationPrefs.ticketNotifications,
                        onChanged: (value) {
                          ref.read(notificationPreferencesProvider.notifier).toggleTicketNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? 'Ticket notifications enabled' : 'Ticket notifications disabled'),
                              backgroundColor: value ? Colors.green : Colors.orange,
                            ),
                          );
                        },
                      ),
                    ),
                    _buildSettingsTile(
                      context,
                      Icons.bedtime_outlined,
                      'Sessiz Saatler',
                      'Belirli saatlerde bildirim alma',
                      onTap: () => _showQuietHoursDialog(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Privacy settings section
                _buildSettingsSection(
                  context,
                  AppLocalizations.of(context)!.privacy,
                  [
                    _buildSettingsTile(
                      context,
                      Icons.privacy_tip_outlined,
                      AppLocalizations.of(context)!.privacyDataUsage,
                      AppLocalizations.of(context)!.privacyPolicy,
                      onTap: () => _openPrivacyScreen(context),
                    ),
                    _buildSettingsTile(
                      context,
                      Icons.security_outlined,
                      AppLocalizations.of(context)!.securitySettings,
                      AppLocalizations.of(context)!.featureComingSoon,
                      onTap: () => _showSecuritySettings(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Account management section
                _buildSettingsSection(
                  context,
                  AppLocalizations.of(context)!.account,
                  [
                    _buildSettingsTile(
                      context,
                      Icons.help_outline,
                      AppLocalizations.of(context)!.helpSupport,
                      AppLocalizations.of(context)!.shareYourSuggestions,
                      onTap: () => _showHelpSupport(context),
                    ),
                    _buildSettingsTile(
                      context,
                      Icons.info_outline,
                      AppLocalizations.of(context)!.aboutApp,
                      'StubStreet',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      Icons.logout,
                      AppLocalizations.of(context)!.logout,
                      AppLocalizations.of(context)!.featureComingSoon,
                      textColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () => _showLogoutConfirmation(context, ref),
                    ),
                  ],
                ),

                const SizedBox(height: 40), // Extra space at bottom for scrolling
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create consistent settings sections with titles
  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(children: tiles),
        ),
      ],
    );
  }

  // Helper method to create consistent settings tiles with proper styling
  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
      onTap: onTap,
    );
  }

  // Show about dialog with app information
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppLocalizations.of(context)!.appTitle,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: const Icon(
          Icons.confirmation_number_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        Text(AppLocalizations.of(context)!.appSubtitle),
        const SizedBox(height: 16),
        Text(
          '© 2024 Bilet Sokağı. Tüm hakları saklıdır.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // Show logout confirmation dialog with proper user feedback
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close settings sheet
              
              // Perform logout operation using auth provider
              try {
                await ref.read(authRepositoryProvider).signOut();
                // Navigation to login screen will be handled by auth state changes
              } catch (e) {
                // Show error if logout fails
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Çıkış yapılırken hata oluştu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  // Show theme selection dialog
  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Sistem'),
              subtitle: const Text('Cihaz ayarlarını takip et'),
              onTap: () {
                ref.read(themeNotifierProvider.notifier).setTheme(ThemeMode.system);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema: Sistem')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Açık'),
              subtitle: const Text('Açık tema kullan'),
              onTap: () {
                ref.read(themeNotifierProvider.notifier).setTheme(ThemeMode.light);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema: Açık')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Koyu'),
              subtitle: const Text('Koyu tema kullan'),
              onTap: () {
                ref.read(themeNotifierProvider.notifier).setTheme(ThemeMode.dark);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema: Koyu')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Show privacy policy dialog
  void _openPrivacyScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _PrivacyDataUsageScreen(),
      ),
    );
  }

  // Inline Privacy & Data Usage screen
  // Keşif: Basit bir ekran ile hukuki metinleri gösteriyoruz
  // Daha sonra ayrı bir dosyaya taşınabilir.
  static const String _privacyContentTr =
      'Gizlilik ve Veri Kullanımı\n\n'
      'Kişisel verileriniz KVKK ve ilgili mevzuata uygun olarak işlenir.\n'
      '• Hangi veriler: kimlik, iletişim, işlem ve teknik veriler\n'
      '• Amaçlar: güvenlik, hizmet sunumu, yasal yükümlülükler, kalite\n'
      '• Haklarınız: bilgilendirme, düzeltme, silme, itiraz\n\n'
      'İletişim: info@biletsokagi.com';

  static const String _privacyContentEn =
      'Privacy & Data Usage\n\n'
      'Your personal data is processed in accordance with applicable laws.\n'
      '• Data: identity, contact, transaction and technical data\n'
      '• Purposes: security, service delivery, legal compliance, quality\n'
      '• Your rights: access, rectification, deletion, objection\n\n'
      'Contact: info@biletsokagi.com';

  static String _localizedPrivacy(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'tr' ? _privacyContentTr : _privacyContentEn;
  }

  

  // Show security settings
  void _showSecuritySettings(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Güvenlik Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Şifre Değiştir'),
              subtitle: const Text('Hesap şifrenizi güncelleyin'),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('İki Faktörlü Doğrulama'),
              subtitle: const Text('Ekstra güvenlik katmanı'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İki faktörlü doğrulama yakında eklenecek'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Aktif Oturumlar'),
              subtitle: const Text('Diğer cihazlardaki oturumları yönet'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Oturum yönetimi yakında eklenecek'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // Show change password dialog
  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mevcut Şifre',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
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
              if (newPasswordController.text == confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifre değiştirme özelliği yakında eklenecek'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifreler eşleşmiyor'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  // Show language selection dialog
  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.read(languageNotifierProvider.notifier).currentLanguage;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dil Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((language) {
            final isSelected = language == currentLanguage;
            
            return ListTile(
              title: Text(language.displayName),
              leading: Radio<AppLanguage>(
                value: language,
                // ignore: deprecated_member_use  
                groupValue: currentLanguage,
                // ignore: deprecated_member_use
                onChanged: (AppLanguage? value) {
                  if (value != null) {
                    ref.read(languageNotifierProvider.notifier).setLanguage(value);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dil ${value.displayName} olarak değiştirildi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },  // Note: groupValue/onChanged are deprecated but migration to RadioTheme requires complex refactoring
              ),
              trailing: isSelected 
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                ref.read(languageNotifierProvider.notifier).setLanguage(language);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dil ${language.displayName} olarak değiştirildi'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  // Show help and support screen
  void _showHelpSupport(BuildContext context) {
    Navigator.pop(context); // Close settings sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpSupportScreen(),
      ),
    );
  }

  // Show quiet hours dialog
  void _showQuietHoursDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sessiz Saatler'),
        content: const Text('Bu özellik yakında eklenecek. Sessiz saatlerde bildirimler susturulacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
