// lib/features/auth/presentation/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Legacy register screen - now redirects to modern 3-stage registration system
/// Eğitimsel açıklama: Bu eski kayıt ekranını koruyoruz ama kullanıcıları modern
/// 3 aşamalı sisteme yönlendiriyoruz: Hesap Bilgileri → Kimlik Doğrulama → Sözleşmeler
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  @override
  void initState() {
    super.initState();
    
    // Redirect to modern 3-stage registration system immediately
    // Neden redirect?: Yeni sisteme geçiş yaparken eski linkleri kırmamak için
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/register/account');
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading indicator while redirecting
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            
            // Informative text
            Text(
              'Kayıt sistemine yönlendiriliyor...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Modern 3 aşamalı kayıt sistemimize hoş geldiniz',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
