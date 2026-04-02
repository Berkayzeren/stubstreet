// lib/core/utils/base32_encoder.dart

/// Base32 encoding/decoding for TOTP
class Base32Encoder {
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  
  static String encode(List<int> bytes) {
    if (bytes.isEmpty) return '';
    
    final result = StringBuffer();
    int buffer = 0;
    int bitsLeft = 0;
    
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      
      while (bitsLeft >= 5) {
        result.write(_alphabet[(buffer >> (bitsLeft - 5)) & 31]);
        bitsLeft -= 5;
      }
    }
    
    if (bitsLeft > 0) {
      result.write(_alphabet[(buffer << (5 - bitsLeft)) & 31]);
    }
    
    // Add padding
    while (result.length % 8 != 0) {
      result.write('=');
    }
    
    return result.toString();
  }
  
  static List<int> decode(String encoded) {
    if (encoded.isEmpty) return [];
    
    // Remove padding
    encoded = encoded.replaceAll('=', '');
    
    final result = <int>[];
    int buffer = 0;
    int bitsLeft = 0;
    
    for (final char in encoded.toUpperCase().split('')) {
      final value = _alphabet.indexOf(char);
      if (value == -1) continue;
      
      buffer = (buffer << 5) | value;
      bitsLeft += 5;
      
      if (bitsLeft >= 8) {
        result.add((buffer >> (bitsLeft - 8)) & 255);
        bitsLeft -= 8;
      }
    }
    
    return result;
  }
}
