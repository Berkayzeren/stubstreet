import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/register_wizard_provider.dart';
import '../widgets/auth_text_field.dart';

class RegisterIdentityScreen extends ConsumerStatefulWidget {
  const RegisterIdentityScreen({super.key});

  @override
  ConsumerState<RegisterIdentityScreen> createState() => _RegisterIdentityScreenState();
}

class _RegisterIdentityScreenState extends ConsumerState<RegisterIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tcknController = TextEditingController();
  final _phoneLocalController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  
  // SMS countdown timer variables
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  bool _canResendSms = true;

  // Basit ülke kodu listesi: bayrak, ülke kodu ve dial code
  final List<_CountryDial> _countries = const [
    _CountryDial(flag: '🇹🇷', name: 'Türkiye', dial: '+90'),
    _CountryDial(flag: '🇺🇸', name: 'United States', dial: '+1'),
    _CountryDial(flag: '🇬🇧', name: 'United Kingdom', dial: '+44'),
    _CountryDial(flag: '🇩🇪', name: 'Deutschland', dial: '+49'),
    _CountryDial(flag: '🇫🇷', name: 'France', dial: '+33'),
    _CountryDial(flag: '🇪🇸', name: 'España', dial: '+34'),
    _CountryDial(flag: '🇮🇹', name: 'Italia', dial: '+39'),
  ];
  late _CountryDial _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.first; // Türkiye varsayılan
  }

  @override
  void dispose() {
    _tcknController.dispose();
    _phoneLocalController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel(); // Cancel timer to prevent memory leaks
    super.dispose();
  }

  String _composeE164() {
    final local = _phoneLocalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return '${_selectedCountry.dial}$local';
  }

  String? _validatePhoneLocal(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final local = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (local.isEmpty) return l10n.phoneRequired;
    // TR için 10 hane bekleriz; diğerlerinde temel uzunluk kontrolü (7-12)
    if (_selectedCountry.dial == '+90') {
      if (local.length != 10) return l10n.phoneLenTurkey;
    } else {
      if (local.length < 7 || local.length > 12) return l10n.phoneLenGeneric;
    }
    final e164 = _composeE164();
    if (!RegExp(r'^\+[1-9]\d{6,14}').hasMatch(e164)) return l10n.invalidPhoneFormat;
    return null;
  }

  String? _validateTckn(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return l10n.tcknRequired;
    if (!RegExp(r'^\d{11}$').hasMatch(raw)) return l10n.tckn11Digits;
    if (raw.startsWith('0')) return l10n.tcknStartsWithZero;
    final digits = raw.split('').map(int.parse).toList();
    final oddSum = digits[0] + digits[2] + digits[4] + digits[6] + digits[8];
    final evenSum = digits[1] + digits[3] + digits[5] + digits[7];
    final d10 = ((oddSum * 7) - evenSum) % 10;
    final d11 = (digits.take(10).reduce((a, b) => a + b)) % 10;
    if (digits[9] != d10) return l10n.invalidTcknK1;
    if (digits[10] != d11) return l10n.invalidTcknK2;
    return null;
  }

  /// Starts the countdown timer to prevent SMS resend for 60 seconds
  /// This prevents spam and follows SMS provider rate limiting best practices
  void _startCountdownTimer() {
    _countdownTimer?.cancel(); // Cancel any existing timer
    _countdownSeconds = 60; // Start with 60 seconds
    _canResendSms = false; // Disable resend button
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdownSeconds--;
          if (_countdownSeconds <= 0) {
            _canResendSms = true; // Re-enable resend button
            timer.cancel(); // Stop the timer
          }
        });
      } else {
        timer.cancel(); // Cancel if widget is disposed
      }
    });
  }

  /// Formats countdown seconds into MM:SS format for display
  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Sends SMS verification code to the provided phone number
  /// Includes comprehensive error handling and starts countdown timer
  Future<void> _sendSms() async {
    // Validate phone number format before attempting to send SMS
    final err = _validatePhoneLocal(_phoneLocalController.text.trim());
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      return;
    }
    
    final e164 = _composeE164();
    setState(() => _isLoading = true);
    
    try {
      await fb_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: e164,
        verificationCompleted: (_) {
          // Auto-verification completed (usually in testing environments)
          debugPrint('Phone verification completed automatically');
        },
        verificationFailed: (e) {
          String humanMessage;
          String? rawMessage;
          String? code;

          // Extract error details for better user feedback
          // Note: 'e' is already fb_auth.FirebaseAuthException in this callback
          code = e.code;
          rawMessage = e.message;

          // Handle specific Firebase Auth error codes with user-friendly messages
          if ((rawMessage ?? '').toLowerCase().contains('region enabled')) {
            humanMessage = 'SMS gönderimi bu bölge için kapalı görünüyor. Firebase Console > Authentication > Sign-in method > Phone bölümünden seçili bölgeleri kontrol edin.';
          } else {
            switch (code) {
              case 'operation-not-allowed':
                humanMessage = 'Telefonla giriş devre dışı. Firebase Console > Authentication > Sign-in method > Phone sağlayıcısını etkinleştirin.';
                break;
              case 'invalid-phone-number':
                humanMessage = 'Geçersiz telefon numarası. Lütfen ülke kodunu seçip yerel numarayı doğru girin.';
                break;
              case 'quota-exceeded':
                humanMessage = 'Günlük SMS kotası aşıldı. Lütfen daha sonra tekrar deneyin veya test numarası kullanın.';
                break;
              case 'captcha-check-failed':
              case 'missing-recaptcha-token':
                humanMessage = 'reCAPTCHA doğrulaması başarısız oldu. Sayfayı yenileyip tekrar deneyin ve reklam engelleyiciyi devre dışı bırakın.';
                break;
              case 'too-many-requests':
                humanMessage = 'Çok fazla istek gönderildi. Lütfen bir süre bekleyip tekrar deneyin.';
                break;
              default:
                humanMessage = rawMessage ?? 'SMS gönderilemedi. Lütfen daha sonra tekrar deneyin.';
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(humanMessage), backgroundColor: Colors.red),
            );
          }
        },
        codeSent: (verificationId, resendToken) {
          // SMS code successfully sent - start countdown timer and update UI
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });
          
          // Start 60-second countdown timer to prevent spam
          _startCountdownTimer();
          
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.smsCodeSent),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Auto-retrieval timeout - store verification ID for manual entry
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60), // 60 second timeout for SMS delivery
      );
    } catch (e) {
      // Handle any unexpected errors during SMS sending
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.smsSendError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verificationId == null) {
      await _sendSms();
      return;
    }
    final smsCode = _codeController.text.trim();
    if (smsCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS kodu gerekli'), backgroundColor: Colors.red));
      return;
    }
    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SMS kodu 6 haneli olmalıdır'), backgroundColor: Colors.red));
      return;
    }

    // Persist identity values
    ref.read(registerWizardProvider.notifier).setIdentity(
          tckn: _tcknController.text.trim(),
          phoneNumber: _composeE164(),
        );
    ref.read(registerWizardProvider.notifier).setVerification(
          verificationId: _verificationId,
          smsCode: smsCode,
        );

    if (mounted) {
      Navigator.of(context).pushNamed('/register/agreements');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _tcknController,
                  labelText: l10n.tcknLabel,
                  keyboardType: TextInputType.number,
                  validator: _validateTckn,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  textInputAction: TextInputAction.next,
                  hintText: l10n.tcknHint,
                ),
                const SizedBox(height: 12),
                // Ülke kodu + bayrak seçici ve yerel numara alanı
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Row(
                    children: [
                      PopupMenuButton<_CountryDial>(
                        tooltip: l10n.selectCountryCode,
                        onSelected: (c) => setState(() => _selectedCountry = c),
                        itemBuilder: (context) => _countries
                            .map((c) => PopupMenuItem<_CountryDial>(
                                  value: c,
                                  child: Row(
                                    children: [
                                      Text(c.flag, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Text('${c.name} (${c.dial})'),
                                    ],
                                  ),
                                ))
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedCountry.flag, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(_selectedCountry.dial, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneLocalController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: l10n.localPhoneHint,
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validatePhoneLocal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // SMS Send/Resend button with countdown timer
                OutlinedButton.icon(
                  onPressed: (_isLoading || !_canResendSms) ? null : _sendSms,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sms_outlined),
                  label: Text(
                    _isLoading 
                      ? l10n.sendingSms
                      : _codeSent && !_canResendSms
                        ? l10n.resendSmsIn(_formatCountdown(_countdownSeconds))
                        : _codeSent 
                          ? l10n.resendSms
                          : l10n.sendSmsCode,
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _codeController,
                    labelText: l10n.smsCodeLabel,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.verified_outlined),
                    textInputAction: TextInputAction.done,
                    hintText: l10n.smsCodeHint,
                    maxLength: 6, // Maksimum 6 karakter sınırı
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Sadece rakam girişi
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Helpful message for users
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.smsInfoSentTo(_composeE164()),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.next),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryDial {
  final String flag;
  final String name;
  final String dial;
  const _CountryDial({required this.flag, required this.name, required this.dial});
}
