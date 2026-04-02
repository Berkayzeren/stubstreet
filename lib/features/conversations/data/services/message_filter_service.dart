// lib/features/conversations/data/services/message_filter_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

final messageFilterServiceProvider = Provider((ref) => MessageFilterService());

class MessageFilterService {
  // Güvenlik için yasaklı kelimeler
  static const List<String> _bannedWords = [
    'whatsapp',
    'telegram',
    'discord',
    'instagram',
    'facebook',
    'twitter',
    'snapchat',
    'tiktok',
    'signal',
    'email',
    'gmail',
    'outlook',
    'phone',
    'telefon',
    'number',
    'numara',
    'contact',
    'iletişim',
    'dışarı',
    'outside',
    'başka',
    'other',
    'app',
    'application',
    'uygulama',
    'platform',
    'site',
    'website',
    'link',
    'url',
    'http',
    'https',
    'www',
    'com',
    'net',
    'org',
  ];

  // Şüpheli kalıplar (regex)
  static const List<String> _suspiciousPatterns = [
    r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b', // Telefon numarası
    r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{2}[-.\s]?\d{2}\b', // TR telefon
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', // Email
    r'(?:https?://)?(?:www\.)?[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+', // URL
    r'\+\d{1,3}\s?\d{3}\s?\d{3}\s?\d{4}', // Uluslararası telefon
    r'\b(?:burada|here|dışarı|outside|başka|other)\s+(?:konuş|talk|mesaj|message|yaz|write)\b', // Aradan çıkarma
  ];

  /// Mesajı filtreler ve güvenlik kontrolü yapar
  FilterResult filterMessage(String message) {
    final cleanMessage = message.toLowerCase().trim();
    
    // Yasaklı kelime kontrolü
    for (final word in _bannedWords) {
      if (cleanMessage.contains(word)) {
        return FilterResult(
          isAllowed: false,
          reason: 'Yasaklı kelime tespit edildi: $word',
          filteredMessage: _replaceWord(message, word),
        );
      }
    }

    // Şüpheli kalıp kontrolü
    for (final pattern in _suspiciousPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(cleanMessage)) {
        return FilterResult(
          isAllowed: false,
          reason: 'Şüpheli içerik tespit edildi',
          filteredMessage: _maskSuspiciousContent(message, regex),
        );
      }
    }

    // Ardışık tekrar kontrolü (spam)
    if (_isSpamMessage(cleanMessage)) {
      return FilterResult(
        isAllowed: false,
        reason: 'Spam tespit edildi',
        filteredMessage: message,
      );
    }

    return FilterResult(
      isAllowed: true,
      reason: null,
      filteredMessage: message,
    );
  }

  /// Yasaklı kelimeleri yıldız ile değiştirir
  String _replaceWord(String message, String word) {
    return message.replaceAll(
      RegExp(word, caseSensitive: false),
      '*' * word.length,
    );
  }

  /// Şüpheli içeriği maskeler
  String _maskSuspiciousContent(String message, RegExp regex) {
    return message.replaceAllMapped(regex, (match) {
      final matchedText = match.group(0);
      return '*' * (matchedText?.length ?? 0);
    });
  }

  /// Spam kontrolü
  bool _isSpamMessage(String message) {
    // Aynı karakterin ardışık tekrarı
    final repeatedChar = RegExp(r'(.)\1{4,}'); // 5+ aynı karakter
    if (repeatedChar.hasMatch(message)) return true;

    // Aynı kelimenin ardışık tekrarı
    final words = message.split(' ');
    if (words.length >= 3) {
      for (int i = 0; i < words.length - 2; i++) {
        if (words[i] == words[i + 1] && words[i] == words[i + 2]) {
          return true;
        }
      }
    }

    return false;
  }

  /// Mesajın güvenli olup olmadığını kontrol eder
  bool isMessageSafe(String message) {
    return filterMessage(message).isAllowed;
  }

  /// Mesajı temizler ve güvenli hale getirir
  String cleanMessage(String message) {
    return filterMessage(message).filteredMessage;
  }
}

/// Filtreleme sonucu
class FilterResult {
  final bool isAllowed;
  final String? reason;
  final String filteredMessage;

  FilterResult({
    required this.isAllowed,
    this.reason,
    required this.filteredMessage,
  });
}
