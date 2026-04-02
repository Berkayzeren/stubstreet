// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../../../../shared_widgets/responsive_form_field.dart';
import '../../../../core/services/app_prefs.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/security_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final bool _obscurePassword = true;
  String? _inactivityMessage;

  @override
  void initState() {
    super.initState();
    _checkLogoutReason();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Check if user was logged out due to inactivity
  Future<void> _checkLogoutReason() async {
    try {
      final secureStorage = SecureStorageService();
      final logoutReason = await secureStorage.getLogoutReason();
      
      if (logoutReason == 'inactivity_timeout') {
        setState(() {
          _inactivityMessage = 'Güvenlik nedeniyle 30 dakika inaktivite sonrası otomatik olarak çıkış yapıldı.';
        });
        
        // Clear the logout reason so it doesn't show again
        await secureStorage.clearLogoutReason();
        
        // Show the message for a few seconds then hide it
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _inactivityMessage = null;
            });
          }
        });
      }
    } catch (e) {
      // Ignore errors - not critical
    }
  }

  String? _validateEmailOrUsername(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.emailOrUsernameRequired;
    }
    
    // Username veya email olabilir, her ikisine de izin ver
    if (value.contains('@')) {
      // Email format kontrolü
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return l10n.invalidEmail;
      }
    } else {
      // Username format kontrolü
      if (value.trim().length < 3) {
        return l10n.usernameMinLength;
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
        return l10n.usernameAllowedChars;
      }
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }

    if (value.length < 6) {
      return l10n.passwordTooShort;
    }

    return null;
  }

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔐 DEBUG: Login başlatılıyor - Email: ${_emailController.text.trim()}');
      
      // SignInNotifier ile giriş yap
      await ref.read(signInNotifierProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      debugPrint('🔐 DEBUG: SignInNotifier.signIn() tamamlandı');

      // SignInNotifier'ın final state'ini kontrol et
      final signInState = ref.read(signInNotifierProvider);
      
      if (signInState.hasError) {
        // Authentication başarısız - hata mesajı göster
        debugPrint('❌ DEBUG: SignIn hatası: ${signInState.error}');
        
        // Başarısız giriş denemesini logla
        await SecurityService().logLoginAttempt(_emailController.text.trim(), false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.loginFailed}: ${signInState.error.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return; // Giriş yapmadan dön
      }

      // Authentication başarılı - guest mode'u temizle ve home'a git
      debugPrint('✅ DEBUG: SignIn başarılı, home sayfasına yönlendiriliyor');
      
      // Başarılı giriş denemesini logla
      await SecurityService().logLoginAttempt(_emailController.text.trim(), true);
      
      await AppPrefs.clearGuestMode();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/home',
          arguments: {
            'isGuestMode': false,
          },
        );
      }
      
    } catch (e) {
      // Exception durumunda hata göster
      debugPrint('❌ DEBUG: Login exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.loginFailed}: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueAsGuest() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Set guest mode flag
      await AppPrefs.setIsGuestUser(true);
      
      if (mounted) {
        // Navigate to home screen with guest mode
        Navigator.of(context).pushReplacementNamed(
          '/home',
          arguments: {
            'isGuestMode': true,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.guestContinueError(e.toString())),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.forgotPassword),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.forgotPasswordDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ResponsiveTextFormField(
                      controller: emailController,
                      labelText: l10n.email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      // We accept either email or username; validation is permissive here.
                      validator: _validateEmailOrUsername,
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          String input = emailController.text.trim();
                          if (input.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.emailRequired),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // If user typed username, resolve to email via public usernameIndex mapping
                          // Why: Users often remember username, not email; we map it safely pre-auth.
                          String resolvedEmail = input;
                          if (!input.contains('@')) {
                            try {
                              final doc = await FirebaseFirestore.instance
                                  .collection('usernameIndex')
                                  .doc(input)
                                  .get();
                              final data = doc.data();
                              final mapped = data?['email'];
                              if (mapped == null || mapped.isEmpty) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.usernameEmailNotFound),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              resolvedEmail = mapped;
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.usernameResolveFailed),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }

                          setState(() {
                            isLoading = true;
                          });

                          // Do not keep Navigator/ScaffoldMessenger across awaits; use context directly with mounted checks
                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .sendPasswordResetEmail(resolvedEmail);
                            
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.passwordResetEmailSent(resolvedEmail),
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.passwordResetEmailFailed(e.toString())),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.sendResetEmail),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;
    // İçerik min yüksekliğini, içeride kullandığımız dikey padding (24 top + 12 bottom) kadar azalt
    final contentMinHeight = availableHeight - 36.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: (keyboardHeight > 0 || availableHeight < 640)
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Ekrana zaten sığan düzenlerde gereksiz dikey boşluğu tamamen kaldır
                  minHeight: contentMinHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Flexible space for responsive design
                SizedBox(height: availableHeight * 0.02),

                // Logo ve başlık - responsive size
                Center(
                  child: Container(
                    width: availableHeight < 600 ? 60 : 100,
                    height: availableHeight < 600 ? 60 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Colors.grey.shade800,
                                Colors.grey.shade700,
                              ]
                            : [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withValues(alpha: 0.8),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.confirmation_number_rounded,
                      size: availableHeight < 600 ? 30 : 45,
                      color: isDark ? Colors.deepPurple[300] : Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: availableHeight < 600 ? 8 : 24),

                // Inactivity timeout message
                if (_inactivityMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      border: Border.all(color: Colors.orange.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _inactivityMessage!,
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: isDark ? Colors.white : Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: availableHeight < 600 ? 24 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: availableHeight < 600 ? 2 : 8),
                Text(
                  l10n.appSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.7),
                    fontSize: availableHeight < 600 ? 14 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: availableHeight < 600 ? 16 : 40),

                // E-posta veya Kullanıcı Adı alanı
                ResponsiveTextFormField(
                  controller: _emailController,
                  labelText: l10n.emailOrUsername,
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(Icons.person_outlined),
                  validator: _validateEmailOrUsername,
                  textInputAction: TextInputAction.next,
                  semanticLabel: 'Email or username input field',
                ),
                SizedBox(height: availableHeight < 600 ? 8 : 16),

                // Şifre alanı
                ResponsiveTextFormField(
                  controller: _passwordController,
                  labelText: l10n.password,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  validator: _validatePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  semanticLabel: 'Password input field',
                ),
                SizedBox(height: availableHeight < 600 ? 4 : 8),

                // Şifremi unuttum
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _showForgotPasswordDialog();
                    },
                    child: Text(
                      l10n.forgotPassword,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade400 
                          : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: availableHeight < 600 ? 16 : 24),

                // Giriş butonu
                ResponsiveButton(
                  text: l10n.login,
                  onPressed: _isLoading ? null : _login,
                  isLoading: _isLoading,
                  width: double.infinity,
                  semanticLabel: 'Login button',
                ),
                SizedBox(height: availableHeight < 600 ? 12 : 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.or,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: availableHeight < 600 ? 12 : 20),

                // Kayıt ol butonu
                ResponsiveButton(
                  text: l10n.createAccount,
                  type: ButtonType.outlined,
                  onPressed: () {
                    Navigator.of(context).pushNamed('/register/account');
                  },
                  width: double.infinity,
                  semanticLabel: 'Create account button',
                ),
                SizedBox(height: availableHeight < 600 ? 8 : 12),

                // Üye olmadan devam et butonu
                TextButton.icon(
                  onPressed: _continueAsGuest,
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  label: Text(l10n.continueAsGuest),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
                // Spacer'ı küçük ekranlarda azaltarak gereksiz scroll alanını düşür
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
