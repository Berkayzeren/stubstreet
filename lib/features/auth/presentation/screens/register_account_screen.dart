import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/register_wizard_provider.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_text_field.dart';
import 'dart:async';
import '../../../../core/validators/password_validator.dart';
import '../../../../shared_widgets/password_strength_indicator.dart';

/// Step 1/3 - Account info
/// Why a separate screen?: Users find a focused, uncluttered form easier. We persist data via Riverpod.
class RegisterAccountScreen extends ConsumerStatefulWidget {
  const RegisterAccountScreen({super.key});

  @override
  ConsumerState<RegisterAccountScreen> createState() => _RegisterAccountScreenState();
}

class _RegisterAccountScreenState extends ConsumerState<RegisterAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordObscured = true;
  
  // Username kontrolü için debounce timer
  Timer? _usernameDebounceTimer;
  String _lastCheckedUsername = '';

  @override
  void initState() {
    super.initState();
    // Username field'da değişiklik olduğunda debounce ile kontrol et
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameDebounceTimer?.cancel(); // Timer'ı iptal et
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  /// Username field değiştiğinde çağrılan method - debounce ile API çağrısını geciktirir
  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    
    // Önceki timer'ı iptal et
    _usernameDebounceTimer?.cancel();
    
    // Yeni timer başlat (500ms bekle)
    _usernameDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (username != _lastCheckedUsername && username.length >= 3) {
        _lastCheckedUsername = username;
        ref.read(usernameAvailabilityNotifierProvider.notifier).checkUsername(username);
      } else if (username.length < 3) {
        // Çok kısa ise kontrol durumunu resetle
        ref.read(usernameAvailabilityNotifierProvider.notifier).reset();
      }
    });
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) return l10n.emailRequired;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return l10n.invalidEmail;
    return null;
  }

  String? _validatePassword(String? value) {
    // Yeni güçlü şifre validatörünü kullan
    return PasswordValidator.validate(value, context: context);
  }

  String? _validateName(String? value, String label) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) return '$label ${l10n.firstNameRequired.split(' ')[1]}';
    if (value.trim().length < 2) return l10n.nameMinLength(label, '2');
    final nameRegex = RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s]+$');
    if (!nameRegex.hasMatch(value.trim())) return l10n.nameLettersOnly(label);
    return null;
  }

  String? _validateUsername(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) return l10n.usernameRequired;
    if (value.trim().length < 3) return l10n.usernameMinLength;
    if (value.trim().length > 20) return l10n.usernameMaxLength;
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) return l10n.usernameAllowedChars;
    if (value.trim() != value) return l10n.usernameNoLeadingTrailingSpace;
    
    // Availability kontrolü - sadece önceki kontrollerin geçtiği durumda
    final availabilityState = ref.read(usernameAvailabilityNotifierProvider);
    return availabilityState.when(
      data: (isAvailable) {
        if (isAvailable == false) return l10n.usernameAlreadyTaken;
        return null; // Kullanılabilir veya henüz kontrol edilmedi
      },
      loading: () => null, // Loading durumdayken hata gösterme
      error: (error, _) => null, // Error durumdayken da hata gösterme, başka yerde handle edilir
    );
  }

  Future<void> _onNext() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.passwordsDontMatch), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Persist values into the wizard state for subsequent steps
    ref.read(registerWizardProvider.notifier).setAccount(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      Navigator.of(context).pushNamed('/register/identity');
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
                Icon(Icons.account_circle_outlined, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 24),

                AuthTextField(
                  controller: _firstNameController,
                  labelText: l10n.firstName,
                  keyboardType: TextInputType.name,
                  validator: (v) => _validateName(v, l10n.firstName),
                  prefixIcon: const Icon(Icons.person_outline),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _lastNameController,
                  labelText: l10n.lastName,
                  keyboardType: TextInputType.name,
                  validator: (v) => _validateName(v, l10n.lastName),
                  prefixIcon: const Icon(Icons.person_outline),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final availabilityState = ref.watch(usernameAvailabilityNotifierProvider);
                    
                    // Username durumuna göre suffix icon belirle
                    Widget? suffixIcon;
                    Color? suffixIconColor;
                    
                    availabilityState.when(
                      data: (isAvailable) {
                        if (isAvailable == true) {
                          suffixIcon = const Icon(Icons.check_circle);
                          suffixIconColor = Colors.green;
                        } else if (isAvailable == false) {
                          suffixIcon = const Icon(Icons.error);
                          suffixIconColor = Colors.red;
                        }
                        // null ise (henüz kontrol edilmedi) icon gösterme
                      },
                      loading: () {
                        suffixIcon = const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      error: (error, _) {
                        suffixIcon = const Icon(Icons.warning);
                        suffixIconColor = Colors.orange;
                      },
                    );
                    
                    return AuthTextField(
                      controller: _usernameController,
                      labelText: l10n.username,
                      keyboardType: TextInputType.text,
                      validator: _validateUsername,
                      prefixIcon: const Icon(Icons.alternate_email),
                      suffixIcon: suffixIcon != null 
                          ? IconTheme(
                              data: IconThemeData(color: suffixIconColor),
                              child: suffixIcon!, // Use non-null assertion since we've already checked it's not null
                            )
                          : null,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.none,
                      hintText: l10n.usernameHint,
                    );
                  },
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _emailController,
                  labelText: l10n.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  prefixIcon: const Icon(Icons.email_outlined),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _passwordController,
                  labelText: l10n.password,
                  obscureText: _passwordObscured,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_passwordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _passwordObscured = !_passwordObscured),
                  ),
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) => setState(() {}), // Rebuild for strength indicator
                ),
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  PasswordStrengthIndicator(
                    password: _passwordController.text,
                    showRequirements: true,
                  ),
                ],
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _confirmPasswordController,
                  labelText: l10n.confirmPassword,
                  obscureText: _passwordObscured,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_passwordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _passwordObscured = !_passwordObscured),
                  ),
                  validator: (v) => v == _passwordController.text ? null : l10n.passwordsDontMatch,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _onNext,
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
