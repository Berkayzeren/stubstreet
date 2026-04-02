import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Güçlü şifre validasyon sınıfı
class PasswordValidator {
  // Şifre gereksinimleri
  static const int minLength = 8;
  static const int maxLength = 128;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;
  
  // Yasaklı şifre listesi
  static const List<String> commonPasswords = [
    '12345678', 'password', 'qwerty', '123456789', 'letmein',
    'football', 'iloveyou', 'admin', 'welcome', 'monkey',
    'password123', '123123', 'abc123', 'Password1', 'password1'
  ];
  
  /// Şifre validasyonu
  static String? validate(String? password, {BuildContext? context}) {
    if (password == null || password.isEmpty) {
      return context != null 
        ? AppLocalizations.of(context)!.passwordRequired 
        : 'Şifre gerekli';
    }
    
    // Uzunluk kontrolü
    if (password.length < minLength) {
      return context != null
        ? AppLocalizations.of(context)!.passwordMinLength(minLength.toString())
        : 'Şifre en az $minLength karakter olmalı';
    }
    
    if (password.length > maxLength) {
      return context != null
        ? AppLocalizations.of(context)!.passwordMaxLength(maxLength.toString())
        : 'Şifre en fazla $maxLength karakter olabilir';
    }
    
    // Büyük harf kontrolü
    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      return context != null
        ? AppLocalizations.of(context)!.passwordRequireUppercase
        : 'Şifre en az bir büyük harf içermeli';
    }
    
    // Küçük harf kontrolü
    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      return context != null
        ? AppLocalizations.of(context)!.passwordRequireLowercase
        : 'Şifre en az bir küçük harf içermeli';
    }
    
    // Rakam kontrolü
    if (requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      return context != null
        ? AppLocalizations.of(context)!.passwordRequireNumber
        : 'Şifre en az bir rakam içermeli';
    }
    
    // Özel karakter kontrolü
    if (requireSpecialChars && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return context != null
        ? AppLocalizations.of(context)!.passwordRequireSpecial
        : 'Şifre en az bir özel karakter içermeli (!@#\$%^&*(),.?":{}|<>)';
    }
    
    // Yaygın şifre kontrolü
    if (commonPasswords.contains(password.toLowerCase())) {
      return context != null
        ? AppLocalizations.of(context)!.passwordTooCommon
        : 'Bu şifre çok yaygın kullanılıyor, lütfen daha güçlü bir şifre seçin';
    }
    
    // Ardışık karakter kontrolü (123, abc, vb.)
    if (_hasSequentialChars(password)) {
      return context != null
        ? AppLocalizations.of(context)!.passwordNoSequential
        : 'Şifre ardışık karakterler içermemeli (123, abc, vb.)';
    }
    
    // Tekrarlayan karakter kontrolü (aaa, 111, vb.)
    if (_hasRepeatingChars(password)) {
      return context != null
        ? AppLocalizations.of(context)!.passwordNoRepeating
        : 'Şifre aynı karakteri üst üste 3 kez içermemeli';
    }
    
    return null; // Geçerli şifre
  }
  
  /// Şifre gücü hesaplama (0-100)
  static int calculateStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    
    // Uzunluk puanı (max 30)
    strength += (password.length * 2).clamp(0, 30);
    
    // Karakter çeşitliliği (max 40)
    if (password.contains(RegExp(r'[a-z]'))) strength += 10;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 10;
    if (password.contains(RegExp(r'[0-9]'))) strength += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 10;
    
    // Karmaşıklık bonusu (max 30)
    if (password.length >= 12) strength += 10;
    if (password.length >= 16) strength += 10;
    if (!_hasSequentialChars(password) && !_hasRepeatingChars(password)) strength += 10;
    
    return strength.clamp(0, 100);
  }
  
  /// Şifre gücü seviyesi
  static PasswordStrength getStrengthLevel(String password) {
    final strength = calculateStrength(password);
    
    if (strength < 20) return PasswordStrength.veryWeak;
    if (strength < 40) return PasswordStrength.weak;
    if (strength < 60) return PasswordStrength.fair;
    if (strength < 80) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
  
  /// Şifre gücü rengi
  static Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak:
        return Colors.red[900]!;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.lightGreen;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }
  
  /// Şifre gücü metni
  static String getStrengthText(PasswordStrength strength, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (strength) {
      case PasswordStrength.veryWeak:
        return l10n.passwordVeryWeak;
      case PasswordStrength.weak:
        return l10n.passwordWeak;
      case PasswordStrength.fair:
        return l10n.passwordFair;
      case PasswordStrength.good:
        return l10n.passwordGood;
      case PasswordStrength.strong:
        return l10n.passwordStrong;
    }
  }
  
  /// Ardışık karakter kontrolü
  static bool _hasSequentialChars(String password) {
    const sequences = [
      '0123456789',
      'abcdefghijklmnopqrstuvwxyz',
      'qwertyuiop',
      'asdfghjkl',
      'zxcvbnm'
    ];
    
    final lowerPassword = password.toLowerCase();
    
    for (final seq in sequences) {
      for (int i = 0; i <= seq.length - 3; i++) {
        if (lowerPassword.contains(seq.substring(i, i + 3))) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Tekrarlayan karakter kontrolü
  static bool _hasRepeatingChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }
  
  /// Kullanıcı bilgisi içerme kontrolü
  static bool containsUserInfo(String password, {
    String? username,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    final lowerPassword = password.toLowerCase();
    
    if (username != null && lowerPassword.contains(username.toLowerCase())) {
      return true;
    }
    
    if (email != null) {
      final emailName = email.split('@').first.toLowerCase();
      if (lowerPassword.contains(emailName)) {
        return true;
      }
    }
    
    if (firstName != null && firstName.length > 2 && 
        lowerPassword.contains(firstName.toLowerCase())) {
      return true;
    }
    
    if (lastName != null && lastName.length > 2 && 
        lowerPassword.contains(lastName.toLowerCase())) {
      return true;
    }
    
    return false;
  }
}

/// Şifre gücü seviyeleri
enum PasswordStrength {
  veryWeak,
  weak,
  fair,
  good,
  strong
}
