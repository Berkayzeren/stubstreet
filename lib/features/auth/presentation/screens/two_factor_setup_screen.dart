// lib/features/auth/presentation/screens/two_factor_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/two_factor_auth_service.dart';
import '../../../../core/services/two_factor_auth_types.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../shared_widgets/responsive_form_field.dart';

class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _totpCodeController = TextEditingController();
  
  late TwoFactorAuthService _twoFactorService;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  // TOTP setup data
  String? _totpSecret;
  String? _qrCodeUri;
  String? _manualEntryKey;
  
  // SMS setup data
  bool _smsCodeSent = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _twoFactorService = TwoFactorAuthService(FirebaseService().firestore);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _totpCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İki Faktörlü Kimlik Doğrulama'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hesabınızı Güvende Tutun',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'İki faktörlü doğrulama, hesabınıza ekstra bir güvenlik katmanı ekler.',
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

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.sms),
                  text: 'SMS',
                ),
                Tab(
                  icon: Icon(Icons.qr_code),
                  text: 'Authenticator App',
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSMSSetup(),
                _buildTOTPSetup(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSMSSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMS ile Doğrulama',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Telefon numaranıza SMS ile doğrulama kodu gönderilecek.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          if (!_smsCodeSent) ...[
            ResponsiveTextFormField(
              controller: _phoneController,
              labelText: 'Telefon Numarası',
              hintText: '+90 5XX XXX XX XX',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone),
              validator: _validatePhoneNumber,
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendSMSCode,
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
                    : const Text('SMS Kodu Gönder'),
              ),
            ),
          ] else ...[
            ResponsiveTextFormField(
              controller: _smsCodeController,
              labelText: 'SMS Doğrulama Kodu',
              hintText: '6 haneli kod',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.sms),
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _smsCodeSent = false;
                      _smsCodeController.clear();
                    });
                  },
                  child: const Text('Telefon Numarasını Değiştir'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _sendSMSCode,
                  child: const Text('Kodu Tekrar Gönder'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifySMSCode,
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
                    : const Text('SMS Kodunu Doğrula'),
              ),
            ),
          ],

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

          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTOTPSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Authenticator App ile Doğrulama',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Google Authenticator, Authy gibi uygulamalarla doğrulama.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          if (_qrCodeUri == null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _setupTOTP,
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
                    : const Text('TOTP Kurulumunu Başlat'),
              ),
            ),
          ] else ...[
            // QR Code section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  const Text(
                    '1. QR Kodu Tarayın',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: _qrCodeUri!,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manual entry section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. Manuel Giriş (Opsiyonel)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'QR kodu tarayamıyorsanız, bu kodu manuel olarak girin:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _manualEntryKey ?? '',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _totpSecret ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kod panoya kopyalandı'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verification section
            const Text(
              '3. Doğrulama Kodunu Girin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Authenticator uygulamanızda görünen 6 haneli kodu girin:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            ResponsiveTextFormField(
              controller: _totpCodeController,
              labelText: 'TOTP Doğrulama Kodu',
              hintText: '6 haneli kod',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.security),
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyTOTPCode,
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
                    : const Text('TOTP Kodunu Doğrula'),
              ),
            ),
          ],

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

          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası gerekli';
    }
    
    // Basic phone number validation
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (!phoneRegex.hasMatch(cleanNumber)) {
      return 'Geçerli bir telefon numarası girin';
    }
    
    return null;
  }

  Future<void> _sendSMSCode() async {
    if (_validatePhoneNumber(_phoneController.text) != null) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir telefon numarası girin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userId = FirebaseService().currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      final message = await _twoFactorService.setupSMS2FA(
        userId: userId,
        phoneNumber: _phoneController.text.trim(),
      );

      setState(() {
        _smsCodeSent = true;
        _successMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifySMSCode() async {
    if (_smsCodeController.text.trim().length != 6) {
      setState(() {
        _errorMessage = 'Lütfen 6 haneli doğrulama kodunu girin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userId = FirebaseService().currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      final config = await _twoFactorService.verify2FASetup(
        userId: userId,
        verificationCode: _smsCodeController.text.trim(),
        method: TwoFactorMethod.sms,
      );

      // Show success and backup codes
      if (mounted) {
        await _showSetupSuccess(config);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setupTOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userId = FirebaseService().currentUser?.uid;
      final userEmail = FirebaseService().currentUser?.email;
      
      if (userId == null || userEmail == null) {
        throw Exception('Kullanıcı bilgileri bulunamadı.');
      }

      final result = await _twoFactorService.setupTOTP2FA(
        userId: userId,
        userEmail: userEmail,
      );

      setState(() {
        _totpSecret = result['secret'] as String;
        _qrCodeUri = result['qrCodeUri'] as String;
        _manualEntryKey = result['manualEntryKey'] as String;
        _successMessage = result['message'] as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyTOTPCode() async {
    if (_totpCodeController.text.trim().length != 6) {
      setState(() {
        _errorMessage = 'Lütfen 6 haneli doğrulama kodunu girin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userId = FirebaseService().currentUser?.uid;
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı.');
      }

      final config = await _twoFactorService.verify2FASetup(
        userId: userId,
        verificationCode: _totpCodeController.text.trim(),
        method: TwoFactorMethod.totp,
      );

      // Show success and backup codes
      if (mounted) {
        await _showSetupSuccess(config);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showSetupSuccess(TwoFactorConfig config) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('2FA Aktif!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İki faktörlü kimlik doğrulama başarıyla aktif edildi.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Yedek Kodlarınız:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: config.backupCodes.map((code) => 
                  Text(
                    code,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu kodları güvenli bir yerde saklayın. Telefonunuzu kaybederseniz bu kodlarla giriş yapabilirsiniz.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
