// lib/core/services/fraud_detection_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'fraud_detection_types.dart';

/// Service for detecting fraudulent purchase patterns
class FraudDetectionService {
  final FirebaseFirestore _firestore;
  
  FraudDetectionService(this._firestore);

  /// Analyze a purchase for fraud patterns
  Future<FraudDetectionResult> analyzePurchase({
    required String userId,
    required String ticketId,
    required double amount,
    required String currency,
    required String paymentMethod,
    String? deviceId,
    String? ipAddress,
    Map<String, dynamic>? userAgent,
  }) async {
    try {
      developer.log(
        'Starting fraud analysis for user: $userId, ticket: $ticketId, amount: $amount',
        name: 'FraudDetectionService',
      );

      double totalRiskScore = 0.0;
      List<String> riskFactors = [];
      Map<String, dynamic> metadata = {};

      // 1. Analyze user purchase history
      final historyResult = await _analyzeUserHistory(userId, amount);
      totalRiskScore += historyResult.score;
      riskFactors.addAll(historyResult.factors);
      metadata['historyAnalysis'] = historyResult.metadata;

      // 2. Analyze velocity patterns (rapid purchases)
      final velocityResult = await _analyzeVelocityPatterns(userId);
      totalRiskScore += velocityResult.score;
      riskFactors.addAll(velocityResult.factors);
      metadata['velocityAnalysis'] = velocityResult.metadata;

      // 3. Analyze amount patterns
      final amountResult = await _analyzeAmountPatterns(userId, amount);
      totalRiskScore += amountResult.score;
      riskFactors.addAll(amountResult.factors);
      metadata['amountAnalysis'] = amountResult.metadata;

      // 4. Analyze ticket patterns
      final ticketResult = await _analyzeTicketPatterns(ticketId, userId);
      totalRiskScore += ticketResult.score;
      riskFactors.addAll(ticketResult.factors);
      metadata['ticketAnalysis'] = ticketResult.metadata;

      // 5. Analyze payment method patterns
      final paymentResult = await _analyzePaymentPatterns(userId, paymentMethod);
      totalRiskScore += paymentResult.score;
      riskFactors.addAll(paymentResult.factors);
      metadata['paymentAnalysis'] = paymentResult.metadata;

      // 6. Analyze time patterns
      final timeResult = await _analyzeTimePatterns(userId);
      totalRiskScore += timeResult.score;
      riskFactors.addAll(timeResult.factors);
      metadata['timeAnalysis'] = timeResult.metadata;

      // 7. Analyze device/IP patterns (if available)
      if (deviceId != null || ipAddress != null) {
        final deviceResult = await _analyzeDevicePatterns(userId, deviceId, ipAddress);
        totalRiskScore += deviceResult.score;
        riskFactors.addAll(deviceResult.factors);
        metadata['deviceAnalysis'] = deviceResult.metadata;
      }

      // Normalize risk score (0.0 - 1.0)
      final normalizedScore = math.min(1.0, totalRiskScore);
      
      // Determine risk level and action
      final riskLevel = _determineRiskLevel(normalizedScore);
      final shouldBlock = _shouldBlockTransaction(riskLevel, normalizedScore);
      final recommendedAction = _getRecommendedAction(riskLevel, riskFactors);

      final result = FraudDetectionResult(
        riskLevel: riskLevel,
        riskScore: normalizedScore,
        riskFactors: riskFactors,
        metadata: metadata,
        shouldBlock: shouldBlock,
        recommendedAction: recommendedAction,
      );

      // Log the fraud analysis
      await _logFraudAnalysis(userId, ticketId, result);

      developer.log(
        'Fraud analysis completed: Risk Level: ${riskLevel.name}, Score: $normalizedScore, Factors: ${riskFactors.length}',
        name: 'FraudDetectionService',
      );

      return result;
    } catch (e) {
      developer.log(
        'Error during fraud analysis: $e',
        name: 'FraudDetectionService',
      );
      
      // Return safe default on error
      return FraudDetectionResult(
        riskLevel: FraudRiskLevel.medium,
        riskScore: 0.5,
        riskFactors: ['analysis_error'],
        metadata: {'error': e.toString()},
        shouldBlock: false,
        recommendedAction: 'manual_review',
      );
    }
  }

  /// Analyze user's purchase history for suspicious patterns
  Future<_AnalysisResult> _analyzeUserHistory(String userId, double currentAmount) async {
    try {
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      final last7Days = now.subtract(const Duration(days: 7));
      final last24Hours = now.subtract(const Duration(hours: 24));

      // Get user's order history
      final ordersQuery = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(last30Days))
          .orderBy('createdAt', descending: true)
          .get();

      final orders = ordersQuery.docs;
      double riskScore = 0.0;
      List<String> factors = [];
      Map<String, dynamic> metadata = {};

      // Calculate purchase metrics
      final totalOrders = orders.length;
      final last7DaysOrders = orders.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(last7Days);
      }).length;
      
      final last24HoursOrders = orders.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(last24Hours);
      }).length;

      final totalAmount = orders.fold<double>(0.0, (total, doc) {
        return total + (doc.data()['totalAmount'] as num).toDouble();
      });

      final avgAmount = totalOrders > 0 ? totalAmount / totalOrders : 0.0;

      metadata.addAll({
        'totalOrders30Days': totalOrders,
        'ordersLast7Days': last7DaysOrders,
        'ordersLast24Hours': last24HoursOrders,
        'totalAmount30Days': totalAmount,
        'averageAmount': avgAmount,
        'currentAmount': currentAmount,
      });

      // Risk factors analysis
      
      // 1. Too many orders in short time
      if (last24HoursOrders >= 5) {
        riskScore += 0.3;
        factors.add('high_frequency_24h');
      } else if (last24HoursOrders >= 3) {
        riskScore += 0.2;
        factors.add('medium_frequency_24h');
      }

      if (last7DaysOrders >= 15) {
        riskScore += 0.25;
        factors.add('high_frequency_7d');
      }

      // 2. Unusual amount patterns
      if (avgAmount > 0 && currentAmount > avgAmount * 5) {
        riskScore += 0.3;
        factors.add('unusually_high_amount');
      } else if (avgAmount > 0 && currentAmount > avgAmount * 2) {
        riskScore += 0.15;
        factors.add('higher_than_average_amount');
      }

      // 3. New user with high activity
      if (totalOrders <= 2 && currentAmount > 1000) {
        riskScore += 0.25;
        factors.add('new_user_high_amount');
      }

      // 4. Sudden spending increase
      if (totalOrders > 5) {
        final recentAmount = orders.take(5).fold<double>(0.0, (total, doc) {
          return total + (doc.data()['totalAmount'] as num).toDouble();
        });
        final olderAmount = orders.skip(5).take(5).fold<double>(0.0, (total, doc) {
          return total + (doc.data()['totalAmount'] as num).toDouble();
        });
        
        if (olderAmount > 0 && recentAmount > olderAmount * 3) {
          riskScore += 0.2;
          factors.add('sudden_spending_increase');
        }
      }

      return _AnalysisResult(riskScore, factors, metadata);
    } catch (e) {
      developer.log('Error analyzing user history: $e', name: 'FraudDetectionService');
      return _AnalysisResult(0.1, ['history_analysis_error'], {'error': e.toString()});
    }
  }

  /// Analyze velocity patterns (rapid successive purchases)
  Future<_AnalysisResult> _analyzeVelocityPatterns(String userId) async {
    try {
      final now = DateTime.now();
      final last1Hour = now.subtract(const Duration(hours: 1));
      final last10Minutes = now.subtract(const Duration(minutes: 10));

      final recentOrdersQuery = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(last1Hour))
          .orderBy('createdAt', descending: true)
          .get();

      final recentOrders = recentOrdersQuery.docs;
      double riskScore = 0.0;
      List<String> factors = [];
      Map<String, dynamic> metadata = {};

      final ordersLast10Min = recentOrders.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(last10Minutes);
      }).length;

      metadata.addAll({
        'ordersLast1Hour': recentOrders.length,
        'ordersLast10Minutes': ordersLast10Min,
      });

      // Check for rapid purchases
      if (ordersLast10Min >= 3) {
        riskScore += 0.4;
        factors.add('rapid_purchases_10min');
      } else if (ordersLast10Min >= 2) {
        riskScore += 0.2;
        factors.add('quick_successive_purchases');
      }

      if (recentOrders.length >= 5) {
        riskScore += 0.3;
        factors.add('high_velocity_1hour');
      }

      // Check time gaps between purchases
      if (recentOrders.length >= 2) {
        final timestamps = recentOrders.map((doc) {
          return (doc.data()['createdAt'] as Timestamp).toDate();
        }).toList();
        
        timestamps.sort();
        
        int rapidPairs = 0;
        for (int i = 1; i < timestamps.length; i++) {
          final gap = timestamps[i].difference(timestamps[i-1]);
          if (gap.inMinutes < 2) {
            rapidPairs++;
          }
        }
        
        if (rapidPairs >= 2) {
          riskScore += 0.25;
          factors.add('multiple_rapid_pairs');
        }
        
        metadata['averageTimeBetweenOrders'] = timestamps.length > 1 
            ? timestamps.last.difference(timestamps.first).inMinutes / (timestamps.length - 1)
            : 0;
      }

      return _AnalysisResult(riskScore, factors, metadata);
    } catch (e) {
      developer.log('Error analyzing velocity patterns: $e', name: 'FraudDetectionService');
      return _AnalysisResult(0.1, ['velocity_analysis_error'], {'error': e.toString()});
    }
  }

  /// Analyze amount patterns for suspicious behavior
  Future<_AnalysisResult> _analyzeAmountPatterns(String userId, double currentAmount) async {
    try {
      // Get platform-wide statistics for comparison
      final statsQuery = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'confirmed')
          .orderBy('createdAt', descending: true)
          .limit(1000)
          .get();

      final orders = statsQuery.docs;
      double riskScore = 0.0;
      List<String> factors = [];
      Map<String, dynamic> metadata = {};

      if (orders.isNotEmpty) {
        final amounts = orders.map((doc) => (doc.data()['totalAmount'] as num).toDouble()).toList();
        amounts.sort();
        
        final median = amounts.length % 2 == 0
            ? (amounts[amounts.length ~/ 2 - 1] + amounts[amounts.length ~/ 2]) / 2
            : amounts[amounts.length ~/ 2];
        
        final q75 = amounts[(amounts.length * 0.75).floor()];
        final q90 = amounts[(amounts.length * 0.90).floor()];
        final q95 = amounts[(amounts.length * 0.95).floor()];

        metadata.addAll({
          'platformMedianAmount': median,
          'platformQ75Amount': q75,
          'platformQ90Amount': q90,
          'platformQ95Amount': q95,
          'currentAmount': currentAmount,
        });

        // Risk scoring based on amount percentiles
        if (currentAmount > q95) {
          riskScore += 0.3;
          factors.add('amount_above_95th_percentile');
        } else if (currentAmount > q90) {
          riskScore += 0.2;
          factors.add('amount_above_90th_percentile');
        } else if (currentAmount > q75 * 2) {
          riskScore += 0.15;
          factors.add('amount_significantly_above_average');
        }

        // Check for round number patterns (potential testing)
        if (currentAmount % 100 == 0 && currentAmount >= 500) {
          riskScore += 0.1;
          factors.add('round_number_pattern');
        }
      }

      // Check for specific suspicious amounts
      final suspiciousAmounts = [1.0, 5.0, 10.0, 100.0]; // Test amounts
      if (suspiciousAmounts.contains(currentAmount)) {
        riskScore += 0.15;
        factors.add('suspicious_test_amount');
      }

      return _AnalysisResult(riskScore, factors, metadata);
    } catch (e) {
      developer.log('Error analyzing amount patterns: $e', name: 'FraudDetectionService');
      return _AnalysisResult(0.1, ['amount_analysis_error'], {'error': e.toString()});
    }
  }

  /// Analyze ticket-specific patterns
  Future<_AnalysisResult> _analyzeTicketPatterns(String ticketId, String userId) async {
    try {
      double riskScore = 0.0;
      List<String> factors = [];
      Map<String, dynamic> metadata = {};

      // Get ticket information
      final ticketDoc = await _firestore.collection('tickets').doc(ticketId).get();
      if (!ticketDoc.exists) {
        factors.add('ticket_not_found');
        return _AnalysisResult(0.2, factors, metadata);
      }

      final ticketData = ticketDoc.data()!;
      final sellerId = ticketData['sellerId'] as String?;
      final eventDate = ticketData['eventDate'] as Timestamp?;
      final price = (ticketData['price'] as num?)?.toDouble() ?? 0.0;

      metadata.addAll({
        'ticketId': ticketId,
        'sellerId': sellerId,
        'price': price,
        'eventDate': eventDate?.toDate().toIso8601String(),
      });

      // Check if buyer and seller are the same (self-purchase)
      if (sellerId == userId) {
        riskScore += 0.8;
        factors.add('self_purchase_attempt');
      }

      // Check for rapid purchases of tickets from same seller
      if (sellerId != null) {
        final recentPurchasesQuery = await _firestore
            .collection('orders')
            .where('buyerId', isEqualTo: userId)
            .where('sellerId', isEqualTo: sellerId)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 24))
            ))
            .get();

        if (recentPurchasesQuery.docs.length >= 3) {
          riskScore += 0.3;
          factors.add('multiple_purchases_same_seller');
        }
      }

      // Check event timing
      if (eventDate != null) {
        final eventDateTime = eventDate.toDate();
        final now = DateTime.now();
        final timeUntilEvent = eventDateTime.difference(now);

        // Last-minute purchases can be suspicious
        if (timeUntilEvent.inHours < 2 && timeUntilEvent.inHours > 0) {
          riskScore += 0.2;
          factors.add('last_minute_purchase');
        }
        
        // Purchases for past events
        if (eventDateTime.isBefore(now)) {
          riskScore += 0.4;
          factors.add('past_event_purchase');
        }

        metadata['hoursUntilEvent'] = timeUntilEvent.inHours;
      }

      return _AnalysisResult(riskScore, factors, metadata);
    } catch (e) {
      developer.log('Error analyzing ticket patterns: $e', name: 'FraudDetectionService');
      return _AnalysisResult(0.1, ['ticket_analysis_error'], {'error': e.toString()});
    }
  }

  /// Analyze payment method patterns
  Future<_AnalysisResult> _analyzePaymentPatterns(String userId, String paymentMethod) async {
    try {
      double riskScore = 0.0;
      List<String> factors = [];
      Map<String, dynamic> metadata = {};

      // Get user's payment history
      final ordersQuery = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final orders = ordersQuery.docs;
      metadata.addAll({
        'currentPaymentMethod': paymentMethod,
        'recentOrdersCount': orders.length,
      });

      if (orders.isNotEmpty) {
        // Analyze payment method consistency
        final paymentMethods = orders.map((doc) {
          return doc.data()['metadata']?['payment_method'] ?? 'unknown';
        }).toSet();

        // Sudden change in payment method
        if (paymentMethods.length > 1 && orders.length >= 5) {
          final recentMethods = orders.take(3).map((doc) {
            return doc.data()['metadata']?['payment_method'] ?? 'unknown';
          }).toSet();
          
          final olderMethods = orders.skip(3).take(5).map((doc) {
            return doc.data()['metadata']?['payment_method'] ?? 'unknown';
          }).toSet();

          if (recentMethods.difference(olderMethods).isNotEmpty) {
            riskScore += 0.15;
            factors.add('payment_method_change');
          }
        }

        metadata['uniquePaymentMethods'] = paymentMethods.toList();
      }

      // Risk scoring by payment method
      switch (paymentMethod.toLowerCase()) {
        case 'paytr':
          // Lower risk for established payment processors
          break;
        case 'cash':
          riskScore += 0.1;
          factors.add('cash_payment_method');
          break;
        default:
          riskScore += 0.05;
          factors.add('unknown_payment_method');
      }

      return _AnalysisResult(riskScore, factors, metadata);
    } catch (e) {
      developer.log('Error analyzing payment patterns: $e', name: 'FraudDetectionService');
      return _AnalysisResult(0.1, ['payment_analysis_error'], {'error': e.toString()});
    }
  }

  /// Analyze time-based patterns
  Future<_AnalysisResult> _analyzeTimePatterns(String userId) async {
    try {
      final now = DateTime.now();
      double riskScore = 0.0;
      List<String> factors = [];
      Map<String, dynamic> metadata = {};

      // Get user's recent orders to analyze timing patterns
      final ordersQuery = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final orders = ordersQuery.docs;
      
      if (orders.isNotEmpty) {
        final orderTimes = orders.map((doc) {
          return (doc.data()['createdAt'] as Timestamp).toDate();
        }).toList();

        // Analyze time distribution
        final hourCounts = <int, int>{};
        for (final time in orderTimes) {
          hourCounts[time.hour] = (hourCounts[time.hour] ?? 0) + 1;
        }

        // Unusual hours (late night/early morning)
        final currentHour = now.hour;
        if ((currentHour >= 2 && currentHour <= 5) || (currentHour >= 23)) {
          riskScore += 0.1;
          factors.add('unusual_hour_purchase');
        }

        // Check for bot-like regular intervals
        if (orderTimes.length >= 3) {
          final intervals = <int>[];
          for (int i = 1; i < orderTimes.length; i++) {
            intervals.add(orderTimes[i-1].difference(orderTimes[i]).inMinutes);
          }
          
          // Check if intervals are suspiciously regular
          if (intervals.length >= 2) {
            final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
            final variance = intervals.map((i) => (i - avgInterval) * (i - avgInterval)).reduce((a, b) => a + b) / intervals.length;
            
            if (variance < 2.0 && avgInterval > 0 && avgInterval < 60) { // Very regular intervals under 1 hour
              riskScore += 0.25;
              factors.add('bot_like_regular_intervals');
            }
          }
        }

        metadata.addAll({
          'currentHour': currentHour,
          'orderHours': orderTimes.map((t) => t.hour).toList(),
          'orderCount': orders.length,
        });
      }

      return _AnalysisResult(riskScore, factors, metadata);
    } catch (e) {
      developer.log('Error analyzing time patterns: $e', name: 'FraudDetectionService');
      return _AnalysisResult(0.1, ['time_analysis_error'], {'error': e.toString()});
    }
  }

  /// Analyze device and IP patterns
  Future<_AnalysisResult> _analyzeDevicePatterns(String userId, String? deviceId, String? ipAddress) async {
    try {
      double riskScore = 0.0;
      List<String> factors = [];
      Map<String, dynamic> metadata = {};

      metadata.addAll({
        'deviceId': deviceId,
        'ipAddress': ipAddress,
      });

      // For now, basic device analysis
      // In production, you'd want more sophisticated device fingerprinting
      
      if (deviceId != null) {
        // Check for device switching
        final recentOrdersQuery = await _firestore
            .collection('orders')
            .where('buyerId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        final deviceIds = recentOrdersQuery.docs.map((doc) {
          return doc.data()['metadata']?['deviceId'] as String?;
        }).where((id) => id != null).toSet();

        if (deviceIds.length > 3) {
          riskScore += 0.2;
          factors.add('multiple_devices');
        }

        metadata['uniqueDevices'] = deviceIds.length;
      }

      if (ipAddress != null) {
        // Basic IP analysis - in production you'd use more sophisticated IP intelligence
        
        // Check for suspicious IP patterns (this is very basic)
        if (ipAddress.startsWith('10.') || ipAddress.startsWith('192.168.') || ipAddress.startsWith('172.')) {
          // Private IP addresses might indicate VPN/proxy use
          riskScore += 0.1;
          factors.add('private_ip_address');
        }
      }

      return _AnalysisResult(riskScore, factors, metadata);
    } catch (e) {
      developer.log('Error analyzing device patterns: $e', name: 'FraudDetectionService');
      return _AnalysisResult(0.1, ['device_analysis_error'], {'error': e.toString()});
    }
  }

  /// Determine risk level based on score
  FraudRiskLevel _determineRiskLevel(double score) {
    if (score >= 0.8) return FraudRiskLevel.critical;
    if (score >= 0.6) return FraudRiskLevel.high;
    if (score >= 0.3) return FraudRiskLevel.medium;
    return FraudRiskLevel.low;
  }

  /// Determine if transaction should be blocked
  bool _shouldBlockTransaction(FraudRiskLevel level, double score) {
    switch (level) {
      case FraudRiskLevel.critical:
        return true;
      case FraudRiskLevel.high:
        return score >= 0.7; // Block only very high scores in high risk
      case FraudRiskLevel.medium:
      case FraudRiskLevel.low:
        return false;
    }
  }

  /// Get recommended action based on risk level and factors
  String _getRecommendedAction(FraudRiskLevel level, List<String> factors) {
    if (factors.contains('self_purchase_attempt')) {
      return 'block_self_purchase';
    }
    
    switch (level) {
      case FraudRiskLevel.critical:
        return 'block_transaction';
      case FraudRiskLevel.high:
        return 'manual_review_required';
      case FraudRiskLevel.medium:
        return 'additional_verification';
      case FraudRiskLevel.low:
        return 'proceed';
    }
  }

  /// Log fraud analysis results
  Future<void> _logFraudAnalysis(String userId, String ticketId, FraudDetectionResult result) async {
    try {
      await _firestore.collection('fraudAnalysis').add({
        'userId': userId,
        'ticketId': ticketId,
        'result': result.toFirestore(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Error logging fraud analysis: $e', name: 'FraudDetectionService');
    }
  }

  /// Get fraud statistics for a user
  Future<Map<String, dynamic>> getUserFraudStats(String userId) async {
    try {
      final analysisQuery = await _firestore
          .collection('fraudAnalysis')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final analyses = analysisQuery.docs;
      
      if (analyses.isEmpty) {
        return {
          'totalAnalyses': 0,
          'averageRiskScore': 0.0,
          'riskLevelDistribution': {},
          'commonRiskFactors': [],
        };
      }

      final riskScores = analyses.map((doc) {
        return doc.data()['result']['riskScore'] as double;
      }).toList();

      final riskLevels = analyses.map((doc) {
        return doc.data()['result']['riskLevel'] as String;
      }).toList();

      final allFactors = <String>[];
      for (final doc in analyses) {
        final factors = List<String>.from(doc.data()['result']['riskFactors'] ?? []);
        allFactors.addAll(factors);
      }

      // Count factor frequency
      final factorCounts = <String, int>{};
      for (final factor in allFactors) {
        factorCounts[factor] = (factorCounts[factor] ?? 0) + 1;
      }

      // Get top risk factors
      final sortedFactors = factorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalAnalyses': analyses.length,
        'averageRiskScore': riskScores.reduce((a, b) => a + b) / riskScores.length,
        'riskLevelDistribution': _countOccurrences(riskLevels),
        'commonRiskFactors': sortedFactors.take(10).map((e) => {
          'factor': e.key,
          'count': e.value,
          'percentage': (e.value / analyses.length * 100).round(),
        }).toList(),
      };
    } catch (e) {
      developer.log('Error getting user fraud stats: $e', name: 'FraudDetectionService');
      return {};
    }
  }

  Map<String, int> _countOccurrences(List<String> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item] = (counts[item] ?? 0) + 1;
    }
    return counts;
  }
}

/// Internal class for analysis results
class _AnalysisResult {
  final double score;
  final List<String> factors;
  final Map<String, dynamic> metadata;

  _AnalysisResult(this.score, this.factors, this.metadata);
}
