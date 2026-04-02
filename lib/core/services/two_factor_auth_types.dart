// lib/core/services/two_factor_auth_types.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 2FA Methods
enum TwoFactorMethod { sms, totp, email }

/// 2FA Status
enum TwoFactorStatus { disabled, enabled, pendingVerification }

/// 2FA Configuration
class TwoFactorConfig {
  final String userId;
  final TwoFactorStatus status;
  final List<TwoFactorMethod> enabledMethods;
  final String? phoneNumber;
  final String? totpSecret;
  final List<String> backupCodes;
  final DateTime? lastUsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  TwoFactorConfig({
    required this.userId,
    required this.status,
    required this.enabledMethods,
    this.phoneNumber,
    this.totpSecret,
    required this.backupCodes,
    this.lastUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'status': status.name,
      'enabledMethods': enabledMethods.map((m) => m.name).toList(),
      'phoneNumber': phoneNumber,
      'totpSecret': totpSecret,
      'backupCodes': backupCodes,
      'lastUsed': lastUsed != null ? Timestamp.fromDate(lastUsed!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TwoFactorConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TwoFactorConfig(
      userId: data['userId'] as String,
      status: TwoFactorStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TwoFactorStatus.disabled,
      ),
      enabledMethods: (data['enabledMethods'] as List<dynamic>?)
              ?.map((m) => TwoFactorMethod.values.firstWhere(
                    (method) => method.name == m,
                    orElse: () => TwoFactorMethod.sms,
                  ))
              .toList() ??
          [],
      phoneNumber: data['phoneNumber'] as String?,
      totpSecret: data['totpSecret'] as String?,
      backupCodes: List<String>.from(data['backupCodes'] ?? []),
      lastUsed: data['lastUsed'] != null
          ? (data['lastUsed'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
