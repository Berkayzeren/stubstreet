// lib/features/auth/presentation/screens/two_factor_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/two_factor_auth_service.dart';
import '../../../../core/services/two_factor_auth_types.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../shared_widgets/responsive_form_field.dart';

class TwoFactorVerificationScreen extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback onVerificationSuccess;

  const TwoFactorVerificationScreen({
    super.key,
    required this.userId,
    required this.onVerificationSuccess,
  });

  @override
  ConsumerState<TwoFactorVerificationScreen> createState() =>
      _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState
    extends ConsumerState<TwoFactorVerificationScreen> {
  final _codeController = TextEditingController();
  late TwoFactorAuthService _twoFactorService;
  
  bool _isLoading = false;
  String? _errorMessage;
  TwoFactorConfig? _config;
  TwoFactorMethod? _selectedMethod;
  bool _showBackupCodes = false;

  @override
  void initState() {
    super.initState();
    _twoFactorService = TwoFactorAuthService(FirebaseService().firestore);
    _loadConfig();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _twoFactorService.getTwoFactorConfig(widget.userId);
      setState(() {
        _config = config;
        if (config != null && config.enabledMethods.isNotEmpty) {
          _selectedMethod = config.enabledMethods.first;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Yapılandırma yüklenemedi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İki Faktörlü Doğrulama'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: _config == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          Theme.of(context).primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.security,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Güvenlik Doğrulaması',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Devam etmek için kimliğinizi doğrulayın',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Method selection
                  if (_config!.enabledMethods.length > 1) ...[
                    const Text(
                      'Doğrulama Yöntemi Seçin:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._config!.enabledMethods.map((method) => 
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: _selectedMethod == method 
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                            : null,
                        child: ListTile(
                          leading: Icon(
                            _selectedMethod == method 
                                ? Icons.radio_button_checked 
                                : Icons.radio_button_unchecked,
                            color: _selectedMethod == method 
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          title: Text(_getMethodName(method)),
                          subtitle: Text(_getMethodDescription(method)),
                          onTap: () {
                            setState(() {
                              _selectedMethod = method;
                              _codeController.clear();
                              _errorMessage = null;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Code input section
                  if (!_showBackupCodes) ...[
                    Text(
                      _getInstructionText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ResponsiveTextFormField(
                      controller: _codeController,
                      labelText: 'Doğrulama Kodu',
                      hintText: '6 haneli kod',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(_getMethodIcon()),
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (value.length == 6) {
                          _verify2FACode();
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    if (_selectedMethod == TwoFactorMethod.sms) ...[
                      TextButton(
                        onPressed: _isLoading ? null : _sendSMSCode,
                        child: const Text('SMS Kodu Tekrar Gönder'),
                      ),
                      const SizedBox(height: 8),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || _codeController.text.length != 6
                            ? null
                            : _verify2FACode,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Doğrula'),
                      ),
                    ),
                  ] else ...[
                    // Backup codes section
                    const Text(
                      'Yedek Kod Girin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cihazınıza erişiminiz yoksa, yedek kodlarınızdan birini girin:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    ResponsiveTextFormField(
                      controller: _codeController,
                      labelText: 'Yedek Kod',
                      hintText: '8 haneli yedek kod',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.backup),
                      maxLength: 8,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || _codeController.text.length != 8
                            ? null
                            : _verify2FACode,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Yedek Kodu Doğrula'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Toggle backup codes
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showBackupCodes = !_showBackupCodes;
                          _codeController.clear();
                          _errorMessage = null;
                        });
                      },
                      child: Text(
                        _showBackupCodes
                            ? 'Normal Doğrulama Koduna Dön'
                            : 'Yedek Kod Kullan',
                      ),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Help text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Yardım',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cihazınıza erişiminiz yoksa yedek kodlarınızı kullanabilirsiniz. Sorun yaşıyorsanız müşteri hizmetleri ile iletişime geçin.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getMethodName(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return 'SMS';
      case TwoFactorMethod.totp:
        return 'Authenticator App';
      case TwoFactorMethod.email:
        return 'E-posta';
    }
  }

  String _getMethodDescription(TwoFactorMethod method) {
    switch (method) {
      case TwoFactorMethod.sms:
        return 'Telefon numaranıza SMS ile kod gönderilir';
      case TwoFactorMethod.totp:
        return 'Authenticator uygulamanızdan kod alın';
      case TwoFactorMethod.email:
        return 'E-posta adresinize kod gönderilir';
    }
  }

  IconData _getMethodIcon() {
    if (_selectedMethod == null) return Icons.security;
    
    switch (_selectedMethod!) {
      case TwoFactorMethod.sms:
        return Icons.sms;
      case TwoFactorMethod.totp:
        return Icons.security;
      case TwoFactorMethod.email:
        return Icons.email;
    }
  }

  String _getInstructionText() {
    if (_selectedMethod == null) return '';
    
    switch (_selectedMethod!) {
      case TwoFactorMethod.sms:
        return 'Telefon numaranıza gönderilen 6 haneli kodu girin:';
      case TwoFactorMethod.totp:
        return 'Authenticator uygulamanızda görünen 6 haneli kodu girin:';
      case TwoFactorMethod.email:
        return 'E-posta adresinize gönderilen 6 haneli kodu girin:';
    }
  }

  Future<void> _sendSMSCode() async {
    if (_selectedMethod != TwoFactorMethod.sms) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final message = await _twoFactorService.send2FACode(
        userId: widget.userId,
        method: TwoFactorMethod.sms,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verify2FACode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || (code.length != 6 && code.length != 8)) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir kod girin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _twoFactorService.verify2FACode(
        userId: widget.userId,
        code: code,
        preferredMethod: _selectedMethod,
      );

      if (isValid) {
        widget.onVerificationSuccess();
      } else {
        setState(() {
          _errorMessage = 'Geçersiz doğrulama kodu. Lütfen tekrar deneyin.';
          _codeController.clear();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Doğrulama hatası: $e';
        _codeController.clear();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
