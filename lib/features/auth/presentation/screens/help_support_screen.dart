// lib/features/auth/presentation/screens/help_support_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';

/// Comprehensive help and support screen with FAQ, contact options, and guides
/// Provides users with self-service support and contact information
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım ve Destek'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.help_outline), text: 'SSS'),
            Tab(icon: Icon(Icons.book_outlined), text: 'Rehber'),
            Tab(icon: Icon(Icons.support_agent), text: 'İletişim'),
            Tab(icon: Icon(Icons.info_outline), text: 'Hakkında'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildGuideTab(),
          _buildContactTab(),
          _buildAboutTab(),
        ],
      ),
    );
  }

  /// FAQ (Sıkça Sorulan Sorular) tab
  Widget _buildFAQTab() {
    final filteredFAQs = _searchQuery.isEmpty
        ? _faqData
        : _faqData
            .where((faq) =>
                faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'SSS\'de ara...',
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
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        
        // FAQ List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredFAQs.length,
            itemBuilder: (context, index) {
              final faq = filteredFAQs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        faq['answer']!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// User guide tab with tutorials and walkthroughs
  Widget _buildGuideTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGuideSection(
          'Başlangıç Rehberi',
          Icons.rocket_launch,
          [
            'Hesap oluşturma ve doğrulama',
            'Profil bilgilerini tamamlama',
            'İlk bilet satın alma',
            'Güvenlik ayarlarını yapma',
          ],
        ),
        const SizedBox(height: 24),
        
        _buildGuideSection(
          'Bilet İşlemleri',
          Icons.confirmation_number,
          [
            'Bilet nasıl satın alınır?',
            'Bilet nasıl satılır?',
            'Bilet transferi nasıl yapılır?',
            'İade ve değişim işlemleri',
          ],
        ),
        const SizedBox(height: 24),
        
        _buildGuideSection(
          'Ödeme ve Güvenlik',
          Icons.payment,
          [
            'Güvenli ödeme yöntemleri',
            'Hesap güvenliği ipuçları',
            'Dolandırıcılıktan korunma',
            'Para iadesi süreçleri',
          ],
        ),
        const SizedBox(height: 24),
        
        _buildGuideSection(
          'Mesajlaşma',
          Icons.chat,
          [
            'Satıcı ile iletişim kurma',
            'Güvenli mesajlaşma kuralları',
            'Emoji ve tepkiler kullanma',
            'Mesaj bildirimleri yönetme',
          ],
        ),
      ],
    );
  }

  /// Contact and support options tab
  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hızlı İşlemler',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildContactOption(
                  Icons.email,
                  'E-posta Gönder',
                  'destek@biletsokagi.com',
                  () => _launchEmail(),
                ),
                _buildContactOption(
                  Icons.phone,
                  'Telefon Desteği',
                  '+90 212 555 0123',
                  () => _launchPhone(),
                ),
                _buildContactOption(
                  Icons.chat_bubble,
                  'Canlı Destek',
                  'Pazartesi-Cuma 09:00-18:00',
                  () => _showLiveChatInfo(),
                ),
                _buildContactOption(
                  Icons.bug_report,
                  'Hata Bildir',
                  'Teknik sorunları bildirin',
                  () => _showBugReportDialog(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Social media and other contacts
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sosyal Medya',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSocialButton(Icons.facebook, 'Facebook', () {}),
                    _buildSocialButton(Icons.alternate_email, 'Twitter', () {}),
                    _buildSocialButton(Icons.camera_alt, 'Instagram', () {}),
                    _buildSocialButton(Icons.video_call, 'YouTube', () {}),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Response times info
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Yanıt Süreleri',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('• E-posta: 2-4 saat'),
                const Text('• Canlı Destek: Anında'),
                const Text('• Telefon: Mesai saatleri içinde'),
                const Text('• Sosyal Medya: 1-2 saat'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// About section with app info and legal
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // App info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Bilet Sokağı',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'Sürüm 1.0.0',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Güvenli ve kolay bilet alım-satım platformu. '
                  'Etkinlik biletlerinizi güvenle alıp satabilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Legal and policies
        Card(
          child: Column(
            children: [
              _buildLegalTile('Kullanım Koşulları', () => _showTermsOfService()),
              _buildLegalTile('Gizlilik Politikası', () => _showPrivacyPolicy()),
              _buildLegalTile('Çerez Politikası', () => _showCookiePolicy()),
              _buildLegalTile('İade ve İptal Koşulları', () => _showRefundPolicy()),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Copyright
        Center(
          child: Text(
            '© 2024 Bilet Sokağı. Tüm hakları saklıdır.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideSection(String title, IconData icon, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Icon(icon, color: Theme.of(context).primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon),
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLegalTile(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Action methods
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'destek@biletsokagi.com',
      queryParameters: {
        'subject': 'Bilet Sokağı - Destek Talebi',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorSnackBar('E-posta uygulaması açılamadı');
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+902125550123');
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackBar('Telefon uygulaması açılamadı');
    }
  }

  void _showLiveChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Canlı Destek'),
        content: const Text(
          'Canlı destek hizmetimiz Pazartesi-Cuma 09:00-18:00 saatleri '
          'arasında aktiftir. Bu saatler dışında e-posta ile ulaşabilirsiniz.',
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

  void _showBugReportDialog() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata Bildir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Karşılaştığınız hatayı detaylı olarak açıklayın:'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Hata açıklaması...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 500,
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
              _showErrorSnackBar('Hata raporu gönderildi. Teşekkürler!');
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    _showLegalDocument('Kullanım Koşulları', _termsOfServiceText);
  }

  void _showPrivacyPolicy() {
    _showLegalDocument('Gizlilik Politikası', _privacyPolicyText);
  }

  void _showCookiePolicy() {
    _showLegalDocument('Çerez Politikası', _cookiePolicyText);
  }

  void _showRefundPolicy() {
    _showLegalDocument('İade ve İptal Koşulları', _refundPolicyText);
  }

  void _showLegalDocument(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // FAQ data
  static const List<Map<String, String>> _faqData = [
    {
      'question': 'Hesap nasıl oluşturabilirim?',
      'answer': 'Ana sayfadaki "Üye Ol" butonuna tıklayarak e-posta adresiniz ve şifrenizle hesap oluşturabilirsiniz. E-posta doğrulaması yapmanız gerekecektir.',
    },
    {
      'question': 'Bilet nasıl satın alabilirim?',
      'answer': 'İstediğiniz etkinliği bulun, satıcıyla iletişime geçin ve güvenli ödeme yöntemimizi kullanarak biletinizi satın alın. Tüm işlemler platformumuz güvencesinde gerçekleşir.',
    },
    {
      'question': 'Biletimi nasıl satabilirim?',
      'answer': 'Profil sayfanızdan "Bilet Ekle" seçeneğini kullanarak bilet bilgilerinizi girin, fotoğraf ekleyin ve fiyat belirleyin. Biletiniz onaylandıktan sonra satışa çıkar.',
    },
    {
      'question': 'Ödeme güvenli mi?',
      'answer': 'Evet, tüm ödemeler SSL şifreleme ile korunur ve güvenilir ödeme sağlayıcıları kullanılır. Kredi kartı bilgileriniz bizde saklanmaz.',
    },
    {
      'question': 'İade alabilir miyim?',
      'answer': 'Satıcının iptal politikasına göre iade alabilirsiniz. Etkinlik iptali durumunda tam iade garantisi sunuyoruz.',
    },
    {
      'question': 'Bilet transfer ücreti var mı?',
      'answer': 'Platform komisyonu %5\'tir. Bu ücret yalnızca başarılı satışlarda tahsil edilir.',
    },
    {
      'question': 'Sahte biletlerden nasıl korunurum?',
      'answer': 'Tüm satıcılar kimlik doğrulamasından geçer. Şüpheli durumları derhal bildirin. Sahte bilet durumunda tam para iadesi garantisi veriyoruz.',
    },
    {
      'question': 'Mesajlarım güvenli mi?',
      'answer': 'Evet, tüm mesajlar şifrelenir ve yalnızca ilgili taraflar görebilir. Platformumuz dışında iletişim kurmayın.',
    },
  ];

  // Legal document texts (shortened for example)
  static const String _termsOfServiceText = '''
1. GENEL HÜKÜMLER
Bu kullanım koşulları, Bilet Sokağı platformunu kullanırken uymanız gereken kuralları belirler.

2. HESAP OLUŞTURMA
Hesap oluştururken doğru bilgiler vermeyi kabul edersiniz.

3. YASAK FAALİYETLER
- Sahte bilet satışı
- Dolandırıcılık
- Platform kurallarını ihlal

4. SORUMLULUK SINIRI
Platform, kullanıcılar arası işlemlerde aracılık eder.

Son güncelleme: Aralık 2024
''';

  static const String _privacyPolicyText = '''
1. TOPLANAN BİLGİLER
- Kişisel bilgiler (ad, e-posta)
- İşlem geçmişi
- Cihaz bilgileri

2. BİLGİLERİN KULLANIMI
- Hizmet sunumu
- Güvenlik sağlama
- İletişim

3. BİLGİ PAYLAŞIMI
Üçüncü taraflarla kişisel bilgilerinizi paylaşmayız.

4. GÜVENLİK
Verileriniz şifrelenir ve güvenli saklanır.

Son güncelleme: Aralık 2024
''';

  static const String _cookiePolicyText = '''
1. ÇEREZ NEDİR?
Çerezler, web siteleri tarafından cihazınızda saklanan küçük dosyalardır.

2. ÇEREZ TÜRLERİ
- Gerekli çerezler
- Analitik çerezler
- Pazarlama çerezleri

3. ÇEREZ YÖNETİMİ
Tarayıcı ayarlarından çerezleri yönetebilirsiniz.

Son güncelleme: Aralık 2024
''';

  static const String _refundPolicyText = '''
1. İADE KOŞULLARI
- Etkinlik iptali
- Satıcı iptal politikası
- Platform hata durumları

2. İADE SÜRECİ
İade talepleri 3-5 iş günü içinde işleme alınır.

3. İADE YÖNTEMLERİ
- Orijinal ödeme yöntemi
- Platform kredisi

Son güncelleme: Aralık 2024
''';
}
