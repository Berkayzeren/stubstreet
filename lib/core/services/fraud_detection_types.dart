// lib/core/services/fraud_detection_types.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Fraud risk levels
enum FraudRiskLevel { low, medium, high, critical }

/// Fraud detection result
class FraudDetectionResult {
  final FraudRiskLevel riskLevel;
  final double riskScore; // 0.0 - 1.0
  final List<String> riskFactors;
  final Map<String, dynamic> metadata;
  final bool shouldBlock;
  final String? recommendedAction;

  FraudDetectionResult({
    required this.riskLevel,
    required this.riskScore,
    required this.riskFactors,
    required this.metadata,
    required this.shouldBlock,
    this.recommendedAction,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'riskLevel': riskLevel.name,
      'riskScore': riskScore,
      'riskFactors': riskFactors,
      'metadata': metadata,
      'shouldBlock': shouldBlock,
      'recommendedAction': recommendedAction,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
