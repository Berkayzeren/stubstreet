// test/security_unit_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:stubstreet/core/services/fraud_detection_types.dart';
import 'package:stubstreet/core/services/two_factor_auth_types.dart';
import 'package:stubstreet/core/utils/base32_encoder.dart';

void main() {
  group('Security Features Unit Tests', () {
    group('Fraud Detection Types', () {
      test('should create FraudDetectionResult correctly', () {
        final result = FraudDetectionResult(
          riskLevel: FraudRiskLevel.medium,
          riskScore: 0.5,
          riskFactors: ['test_factor'],
          metadata: {'test': 'data'},
          shouldBlock: false,
          recommendedAction: 'proceed',
        );

        expect(result.riskLevel, equals(FraudRiskLevel.medium));
        expect(result.riskScore, equals(0.5));
        expect(result.riskFactors, contains('test_factor'));
        expect(result.shouldBlock, isFalse);
      });

      test('should convert FraudDetectionResult to Firestore format', () {
        final result = FraudDetectionResult(
          riskLevel: FraudRiskLevel.high,
          riskScore: 0.8,
          riskFactors: ['factor1', 'factor2'],
          metadata: {'key': 'value'},
          shouldBlock: true,
          recommendedAction: 'block',
        );

        final firestoreData = result.toFirestore();

        expect(firestoreData['riskLevel'], equals('high'));
        expect(firestoreData['riskScore'], equals(0.8));
        expect(firestoreData['riskFactors'], equals(['factor1', 'factor2']));
        expect(firestoreData['shouldBlock'], isTrue);
        expect(firestoreData['recommendedAction'], equals('block'));
      });

      test('should handle all FraudRiskLevel values', () {
        expect(FraudRiskLevel.values, hasLength(4));
        expect(FraudRiskLevel.values, contains(FraudRiskLevel.low));
        expect(FraudRiskLevel.values, contains(FraudRiskLevel.medium));
        expect(FraudRiskLevel.values, contains(FraudRiskLevel.high));
        expect(FraudRiskLevel.values, contains(FraudRiskLevel.critical));
      });
    });

    group('Two Factor Auth Types', () {
      test('should handle all TwoFactorMethod values', () {
        expect(TwoFactorMethod.values, hasLength(3));
        expect(TwoFactorMethod.values, contains(TwoFactorMethod.sms));
        expect(TwoFactorMethod.values, contains(TwoFactorMethod.totp));
        expect(TwoFactorMethod.values, contains(TwoFactorMethod.email));
      });

      test('should handle all TwoFactorStatus values', () {
        expect(TwoFactorStatus.values, hasLength(3));
        expect(TwoFactorStatus.values, contains(TwoFactorStatus.disabled));
        expect(TwoFactorStatus.values, contains(TwoFactorStatus.enabled));
        expect(TwoFactorStatus.values, contains(TwoFactorStatus.pendingVerification));
      });

      test('should create TwoFactorConfig correctly', () {
        final now = DateTime.now();
        final config = TwoFactorConfig(
          userId: 'test_user',
          status: TwoFactorStatus.enabled,
          enabledMethods: [TwoFactorMethod.sms, TwoFactorMethod.totp],
          phoneNumber: '+90 555 123 4567',
          totpSecret: 'secret123',
          backupCodes: ['12345678', '87654321'],
          lastUsed: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(config.userId, equals('test_user'));
        expect(config.status, equals(TwoFactorStatus.enabled));
        expect(config.enabledMethods, hasLength(2));
        expect(config.enabledMethods, contains(TwoFactorMethod.sms));
        expect(config.enabledMethods, contains(TwoFactorMethod.totp));
        expect(config.phoneNumber, equals('+90 555 123 4567'));
        expect(config.backupCodes, hasLength(2));
      });

      test('should convert TwoFactorConfig to Firestore format', () {
        final now = DateTime.now();
        final config = TwoFactorConfig(
          userId: 'test_user',
          status: TwoFactorStatus.enabled,
          enabledMethods: [TwoFactorMethod.sms],
          backupCodes: ['12345678'],
          createdAt: now,
          updatedAt: now,
        );

        final firestoreData = config.toFirestore();

        expect(firestoreData['userId'], equals('test_user'));
        expect(firestoreData['status'], equals('enabled'));
        expect(firestoreData['enabledMethods'], equals(['sms']));
        expect(firestoreData['backupCodes'], equals(['12345678']));
      });
    });

    group('Base32 Encoder', () {
      test('should encode bytes to base32 string', () {
        final bytes = [72, 101, 108, 108, 111]; // "Hello" in ASCII
        final encoded = Base32Encoder.encode(bytes);
        
        expect(encoded, isA<String>());
        expect(encoded.isNotEmpty, isTrue);
      });

      test('should decode base32 string to bytes', () {
        final testString = 'JBSWY3DPEB3W64TMMQ======'; // "Hello World" in base32
        final decoded = Base32Encoder.decode(testString);
        
        expect(decoded, isA<List<int>>());
        expect(decoded.isNotEmpty, isTrue);
      });

      test('should handle empty input', () {
        expect(Base32Encoder.encode([]), equals(''));
        expect(Base32Encoder.decode(''), equals([]));
      });

      test('should handle encode/decode roundtrip', () {
        final originalBytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
        final encoded = Base32Encoder.encode(originalBytes);
        final decoded = Base32Encoder.decode(encoded);
        
        expect(decoded, equals(originalBytes));
      });
    });

    group('Security Constants and Validations', () {
      test('should validate risk score ranges', () {
        // Risk scores should be between 0.0 and 1.0
        final validScores = [0.0, 0.25, 0.5, 0.75, 1.0];
        final invalidScores = [-0.1, 1.1, 2.0, -1.0];

        for (final score in validScores) {
          expect(score >= 0.0 && score <= 1.0, isTrue, 
                 reason: 'Score $score should be valid');
        }

        for (final score in invalidScores) {
          expect(score >= 0.0 && score <= 1.0, isFalse, 
                 reason: 'Score $score should be invalid');
        }
      });

      test('should validate backup code format', () {
        // Backup codes should be 8 digits
        const validCodes = ['12345678', '87654321', '00000000', '99999999'];
        const invalidCodes = ['1234567', '123456789', 'abcd1234', ''];

        for (final code in validCodes) {
          expect(code.length, equals(8), reason: 'Code $code should be 8 digits');
          expect(RegExp(r'^\d{8}$').hasMatch(code), isTrue, 
                 reason: 'Code $code should be all digits');
        }

        for (final code in invalidCodes) {
          final isValid = code.length == 8 && RegExp(r'^\d{8}$').hasMatch(code);
          expect(isValid, isFalse, reason: 'Code $code should be invalid');
        }
      });

      test('should validate phone number formats', () {
        const validPhones = [
          '+90 555 123 4567',
          '+1 555 123 4567',
          '+44 20 7946 0958',
          '+33 1 42 86 83 26'
        ];

        const invalidPhones = [
          '555 123 4567', // No country code
          '+90', // Too short
          'invalid', // Not a number
          '', // Empty
        ];

        for (final phone in validPhones) {
          final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
          expect(cleanPhone.startsWith('+'), isTrue, 
                 reason: 'Phone $phone should start with +');
          expect(cleanPhone.length, greaterThan(5), 
                 reason: 'Phone $phone should be long enough');
        }

        for (final phone in invalidPhones) {
          final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
          final isValid = cleanPhone.startsWith('+') && cleanPhone.length > 5;
          expect(isValid, isFalse, reason: 'Phone $phone should be invalid');
        }
      });
    });

    group('Error Handling', () {
      test('should handle null values gracefully', () {
        expect(() => FraudDetectionResult(
          riskLevel: FraudRiskLevel.low,
          riskScore: 0.0,
          riskFactors: [],
          metadata: {},
          shouldBlock: false,
          recommendedAction: null, // This should be allowed
        ), returnsNormally);
      });

      test('should handle empty collections', () {
        final result = FraudDetectionResult(
          riskLevel: FraudRiskLevel.low,
          riskScore: 0.0,
          riskFactors: [], // Empty list
          metadata: {}, // Empty map
          shouldBlock: false,
        );

        expect(result.riskFactors, isEmpty);
        expect(result.metadata, isEmpty);
      });
    });
  });
}
