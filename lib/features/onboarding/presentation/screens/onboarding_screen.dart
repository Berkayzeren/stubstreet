// lib/features/onboarding/presentation/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/app_prefs.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppPrefs.setOnboardingCompleted(true);
    debugPrint('✅ Onboarding completed, navigating to main route');
    if (!mounted) return;
    
    // Navigate to main route to re-evaluate auth state
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <_OnboardPageContent>[
      const _OnboardPageContent(
        title: 'Güvenli Ticaret',
        description: 'StubStreet ile biletlerinizi güvenle alıp satın.',
        icon: Icons.verified_user,
      ),
      const _OnboardPageContent(
        title: 'Anında Mesajlaşma',
        description: 'Alıcı ve satıcılarla uygulama içi sohbet edin.',
        icon: Icons.chat_bubble_outline,
      ),
      const _OnboardPageContent(
        title: 'Hızlı Ödeme',
        description: 'Stripe ile güvenli ve hızlı ödeme deneyimi.',
        icon: Icons.credit_card,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Ana navigasyon satırı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _finish,
                        child: const Text('Atla'),
                      ),
                      Row(
                        children: List.generate(
                          pages.length,
                          (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _index == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary.withAlpha(77),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _index == pages.length - 1
                            ? _finish
                            : () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                ),
                        child: Text(_index == pages.length - 1 ? 'Başla' : 'İleri'),
                      ),
                    ],
                  ),
                  
                  // "Bir daha gösterme" seçeneği - sadece son sayfada
                  if (_index == pages.length - 1) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        // Onboarding'i tamamla ve bir daha gösterme
                        _finish();
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Tanıtımı bir daha gösterme'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OnboardPageContent extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardPageContent({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


