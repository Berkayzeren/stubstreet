// lib/core/utils/message_filter.dart

import 'package:flutter/foundation.dart';

/// Mesajlarda hassas bilgileri filtrelemek için kullanılan servis
class MessageFilter {
  // Türk telefon numarası regex'i - çeşitli formatları destekler
  static final RegExp _phoneRegex = RegExp(
    r'(\+90\s?)?(\(0?\d{3}\)\s?|\d{3}[-\s]?)?\d{3}[-\s]?\d{2}[-\s]?\d{2}',
    caseSensitive: false,
  );

  // IBAN regex'i - TR ile başlayan 26 haneli
  static final RegExp _ibanRegex = RegExp(
    r'TR\d{2}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{2}',
    caseSensitive: false,
  );

  // Kredi kartı numarası regex'i - 16 haneli
  static final RegExp _creditCardRegex = RegExp(
    r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b',
  );

  // TC Kimlik numarası regex'i - 11 haneli
  static final RegExp _tcNoRegex = RegExp(
    r'\b\d{11}\b',
  );

  // Email regex'i - basit email formatı
  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
  );

  // Adres benzeri uzun metinler - sokak, mahalle, cadde içeren
  static final RegExp _addressRegex = RegExp(
    r'\b(sokak|sk\.|cadde|cd\.|mahalle|mah\.|bulvar|blv\.|apt\.|apartman|no:?\s?\d+)\b',
    caseSensitive: false,
  );

  /// Mesajda hassas bilgi olup olmadığını kontrol eder
  static MessageFilterResult filterMessage(String message) {
    final violations = <String>[];
    final cleanedMessage = message.trim();

    if (cleanedMessage.isEmpty) {
      return MessageFilterResult(
        isAllowed: true,
        filteredMessage: cleanedMessage,
        violations: [],
      );
    }

    // Telefon numarası kontrolü
    if (_phoneRegex.hasMatch(cleanedMessage)) {
      violations.add('Telefon numarası paylaşımı yasaktır');
    }

    // IBAN kontrolü
    if (_ibanRegex.hasMatch(cleanedMessage)) {
      violations.add('IBAN numarası paylaşımı yasaktır');
    }

    // Kredi kartı kontrolü
    if (_creditCardRegex.hasMatch(cleanedMessage)) {
      violations.add('Kredi kartı numarası paylaşımı yasaktır');
    }

    // TC Kimlik numarası kontrolü
    if (_tcNoRegex.hasMatch(cleanedMessage)) {
      violations.add('TC Kimlik numarası paylaşımı yasaktır');
    }

    // Email kontrolü (isteğe bağlı - çok katı olabilir)
    if (_emailRegex.hasMatch(cleanedMessage)) {
      violations.add('Email adresi paylaşımı önerilmez');
    }

    // Adres kontrolü
    if (_addressRegex.hasMatch(cleanedMessage)) {
      violations.add('Adres bilgisi paylaşımı önerilmez');
    }

    // Eğer ihlal varsa mesajı engelle
    final isAllowed = violations.isEmpty;
    
    if (kDebugMode) {
      debugPrint('🔍 Message Filter: "${cleanedMessage.substring(0, cleanedMessage.length > 50 ? 50 : cleanedMessage.length)}..."');
      debugPrint('🔍 Violations: $violations');
      debugPrint('🔍 Is Allowed: $isAllowed');
    }

    return MessageFilterResult(
      isAllowed: isAllowed,
      filteredMessage: cleanedMessage,
      violations: violations,
    );
  }

  /// Hassas bilgileri maskeleyerek temizlenmiş mesaj döndürür
  static String maskSensitiveInfo(String message) {
    String masked = message;

    // Telefon numaralarını maskele
    masked = masked.replaceAllMapped(_phoneRegex, (match) {
      return '[TELEFON NUMARASI]';
    });

    // IBAN'ları maskele
    masked = masked.replaceAllMapped(_ibanRegex, (match) {
      return '[IBAN NUMARASI]';
    });

    // Kredi kartı numaralarını maskele
    masked = masked.replaceAllMapped(_creditCardRegex, (match) {
      return '[KART NUMARASI]';
    });

    // TC numaralarını maskele
    masked = masked.replaceAllMapped(_tcNoRegex, (match) {
      return '[TC NUMARASI]';
    });

    // Email adreslerini maskele
    masked = masked.replaceAllMapped(_emailRegex, (match) {
      return '[EMAIL ADRESI]';
    });

    return masked;
  }

  /// Yasaklı kelimeler listesi (isteğe bağlı genişletilebilir)
  static final List<String> _bannedWords = [
    'dolandırıcı',
    'sahte',
    'kaçak',
    'yasadışı',
    // Daha fazla kelime eklenebilir
  ];

  /// Yasaklı kelime kontrolü
  static bool containsBannedWords(String message) {
    final lowerMessage = message.toLowerCase();
    return _bannedWords.any((word) => lowerMessage.contains(word.toLowerCase()));
  }
}

/// Mesaj filtreleme sonucu
class MessageFilterResult {
  final bool isAllowed;
  final String filteredMessage;
  final List<String> violations;

  const MessageFilterResult({
    required this.isAllowed,
    required this.filteredMessage,
    required this.violations,
  });

  /// İhlallerin kullanıcı dostu açıklaması
  String get violationMessage {
    if (violations.isEmpty) return '';
    
    if (violations.length == 1) {
      return violations.first;
    }
    
    return 'Mesajınızda şu sorunlar bulundu:\n${violations.map((v) => '• $v').join('\n')}';
  }

  @override
  String toString() {
    return 'MessageFilterResult(isAllowed: $isAllowed, violations: $violations)';
  }
}
