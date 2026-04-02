// lib/features/conversations/presentation/providers/message_filter_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_filter_provider.g.dart';

/// Result of message filtering operation
/// 
/// Contains information about whether the message is allowed,
/// the filtered content, and the reason for blocking if applicable.
class MessageFilterResult {
  final bool isAllowed;
  final String filteredMessage;
  final String? reason;
  final List<String> detectedIssues;

  const MessageFilterResult({
    required this.isAllowed,
    required this.filteredMessage,
    this.reason,
    this.detectedIssues = const [],
  });

  @override
  String toString() {
    return 'MessageFilterResult(isAllowed: $isAllowed, reason: $reason, issues: $detectedIssues)';
  }
}

/// Message filtering service provider
/// 
/// This service provides content moderation and filtering capabilities
/// including spam detection, profanity filtering, and threat analysis.
@riverpod
class MessageFilterService extends _$MessageFilterService {
  // Profanity word list (can be loaded from external source)
  static const List<String> _profanityWords = [
    // Add appropriate filtering words here
    'spam', 'scam', 'fake', 'virus', 'hack',
  ];

  // Spam patterns (regex patterns that indicate spam)
  static const List<String> _spamPatterns = [
    r'\b(free money|get rich quick|click here|limited time)\b',
    r'\b(casino|gambling|lottery|jackpot)\b',
    r'\b(viagra|pills|medication)\b',
    r'([A-Z]{3,}.*){3,}', // Excessive caps
    r'(http[s]?://.*){2,}', // Multiple links
    r'(\$\d+|\d+\$){2,}', // Multiple money amounts
  ];

  @override
  MessageFilterService build() {
    return MessageFilterService();
  }

  /// Filter and moderate a message
  /// 
  /// @param message - The message content to filter
  /// @param userId - Optional user ID for user-specific filtering
  /// @param conversationId - Optional conversation ID for context
  /// 
  /// @returns MessageFilterResult with filtering results
  MessageFilterResult filterMessage(
    String message, {
    String? userId,
    String? conversationId,
  }) {
    if (message.trim().isEmpty) {
      return const MessageFilterResult(
        isAllowed: false,
        filteredMessage: '',
        reason: 'Message cannot be empty',
      );
    }

    final detectedIssues = <String>[];
    String filteredContent = message;

    // 1. Check message length
    if (message.length > 5000) {
      return const MessageFilterResult(
        isAllowed: false,
        filteredMessage: '',
        reason: 'Message too long (max 5000 characters)',
        detectedIssues: ['excessive_length'],
      );
    }

    // 2. Check for excessive repetition
    if (_hasExcessiveRepetition(message)) {
      detectedIssues.add('repetitive_content');
      filteredContent = _removeExcessiveRepetition(filteredContent);
    }

    // 3. Check for spam patterns
    final spamCheck = _checkSpamPatterns(message);
    if (spamCheck.isSpam) {
      return MessageFilterResult(
        isAllowed: false,
        filteredMessage: '',
        reason: 'Message contains spam content',
        detectedIssues: ['spam', ...spamCheck.patterns],
      );
    }

    // 4. Check for profanity
    final profanityCheck = _checkProfanity(filteredContent);
    if (profanityCheck.hasProfanity) {
      detectedIssues.add('profanity');
      filteredContent = profanityCheck.filteredContent;
    }

    // 5. Check for threats or harassment
    if (_containsThreats(message)) {
      return const MessageFilterResult(
        isAllowed: false,
        filteredMessage: '',
        reason: 'Message contains inappropriate content',
        detectedIssues: ['threats'],
      );
    }

    // 6. Check for personal information exposure
    final personalInfoCheck = _checkPersonalInfo(filteredContent);
    if (personalInfoCheck.hasPersonalInfo) {
      detectedIssues.add('personal_info');
      filteredContent = personalInfoCheck.filteredContent;
    }

    // 7. Check for excessive caps
    if (_hasExcessiveCaps(message)) {
      detectedIssues.add('excessive_caps');
      filteredContent = _normalizeCaps(filteredContent);
    }

    return MessageFilterResult(
      isAllowed: true,
      filteredMessage: filteredContent.trim(),
      detectedIssues: detectedIssues,
    );
  }

  /// Check if message has excessive repetition
  bool _hasExcessiveRepetition(String message) {
    // Check for repeated characters (more than 4 in a row)
    final charRepeatPattern = RegExp(r'(.)\1{4,}');
    if (charRepeatPattern.hasMatch(message)) return true;

    // Check for repeated words
    final words = message.toLowerCase().split(' ');
    if (words.length < 3) return false;

    int consecutiveRepeats = 0;
    for (int i = 1; i < words.length; i++) {
      if (words[i] == words[i - 1]) {
        consecutiveRepeats++;
        if (consecutiveRepeats >= 3) return true;
      } else {
        consecutiveRepeats = 0;
      }
    }

    return false;
  }

  /// Remove excessive repetition from message
  String _removeExcessiveRepetition(String message) {
    // Remove excessive character repetition (keep max 3)
    String result = message.replaceAllMapped(
      RegExp(r'(.)\1{3,}'),
      (match) => match.group(1)! * 3,
    );

    // Remove excessive word repetition
    final words = result.split(' ');
    final filteredWords = <String>[];
    
    for (int i = 0; i < words.length; i++) {
      if (i == 0 || 
          words[i] != words[i - 1] || 
          (i >= 2 && words[i] != words[i - 2])) {
        filteredWords.add(words[i]);
      }
    }

    return filteredWords.join(' ');
  }

  /// Check for spam patterns
  SpamCheckResult _checkSpamPatterns(String message) {
    final detectedPatterns = <String>[];

    for (final pattern in _spamPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(message)) {
        detectedPatterns.add(pattern);
      }
    }

    // Check for excessive emoji usage (more than 30% of message)
    final emojiCount = _countEmojis(message);
    final totalChars = message.replaceAll(' ', '').length;
    if (totalChars > 0 && (emojiCount / totalChars) > 0.3) {
      detectedPatterns.add('excessive_emojis');
    }

    return SpamCheckResult(
      isSpam: detectedPatterns.isNotEmpty,
      patterns: detectedPatterns,
    );
  }

  /// Check for profanity and filter it
  ProfanityCheckResult _checkProfanity(String message) {
    String filteredContent = message;
    bool hasProfanity = false;

    for (final word in _profanityWords) {
      final regex = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      if (regex.hasMatch(filteredContent)) {
        hasProfanity = true;
        // Replace with asterisks, keeping first and last letter
        final replacement = word.length > 2 
            ? '${word[0]}${'*' * (word.length - 2)}${word[word.length - 1]}'
            : '*' * word.length;
        filteredContent = filteredContent.replaceAll(regex, replacement);
      }
    }

    return ProfanityCheckResult(
      hasProfanity: hasProfanity,
      filteredContent: filteredContent,
    );
  }

  /// Check for threats or harassment
  bool _containsThreats(String message) {
    final threateningPatterns = [
      r'\b(kill|murder|die|death|hurt|harm|violence)\b',
      r'\b(threat|threaten|destroy|attack)\b',
      r'\b(hate|stupid|idiot|moron)\b',
    ];

    final lowerMessage = message.toLowerCase();
    for (final pattern in threateningPatterns) {
      if (RegExp(pattern).hasMatch(lowerMessage)) {
        return true;
      }
    }

    return false;
  }

  /// Check for personal information exposure
  PersonalInfoCheckResult _checkPersonalInfo(String message) {
    String filteredContent = message;
    bool hasPersonalInfo = false;

    // Email pattern
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    if (emailRegex.hasMatch(message)) {
      hasPersonalInfo = true;
      filteredContent = filteredContent.replaceAll(emailRegex, '[email]');
    }

    // Phone number pattern (basic)
    final phoneRegex = RegExp(r'\b(?:\+\d{1,3}\s?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b');
    if (phoneRegex.hasMatch(message)) {
      hasPersonalInfo = true;
      filteredContent = filteredContent.replaceAll(phoneRegex, '[phone]');
    }

    // Credit card pattern (basic)
    final cardRegex = RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b');
    if (cardRegex.hasMatch(message)) {
      hasPersonalInfo = true;
      filteredContent = filteredContent.replaceAll(cardRegex, '[payment info]');
    }

    return PersonalInfoCheckResult(
      hasPersonalInfo: hasPersonalInfo,
      filteredContent: filteredContent,
    );
  }

  /// Check for excessive caps
  bool _hasExcessiveCaps(String message) {
    if (message.length < 10) return false;

    final upperCount = message.replaceAll(RegExp(r'[^A-Z]'), '').length;
    final totalLetters = message.replaceAll(RegExp(r'[^A-Za-z]'), '').length;

    return totalLetters > 0 && (upperCount / totalLetters) > 0.7;
  }

  /// Normalize excessive caps
  String _normalizeCaps(String message) {
    // Convert excessive caps to sentence case
    return message.split(' ').map((word) {
      if (word.length > 2 && word == word.toUpperCase()) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).join(' ');
  }

  /// Count emojis in message (simplified)
  int _countEmojis(String message) {
    // This is a simplified emoji counter
    // In production, you'd want a more comprehensive emoji detection
    final emojiRegex = RegExp(r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]', unicode: true);
    return emojiRegex.allMatches(message).length;
  }
}

/// Helper classes for filter results
class SpamCheckResult {
  final bool isSpam;
  final List<String> patterns;

  const SpamCheckResult({
    required this.isSpam,
    required this.patterns,
  });
}

class ProfanityCheckResult {
  final bool hasProfanity;
  final String filteredContent;

  const ProfanityCheckResult({
    required this.hasProfanity,
    required this.filteredContent,
  });
}

class PersonalInfoCheckResult {
  final bool hasPersonalInfo;
  final String filteredContent;

  const PersonalInfoCheckResult({
    required this.hasPersonalInfo,
    required this.filteredContent,
  });
}
