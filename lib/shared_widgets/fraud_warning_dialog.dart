// lib/shared_widgets/fraud_warning_dialog.dart

import 'package:flutter/material.dart';
import '../core/services/fraud_detection_types.dart';

/// Dialog to show fraud detection warnings to users
class FraudWarningDialog extends StatelessWidget {
  final FraudDetectionResult fraudResult;
  final VoidCallback? onProceed;
  final VoidCallback? onCancel;

  const FraudWarningDialog({
    super.key,
    required this.fraudResult,
    this.onProceed,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getIconForRiskLevel(fraudResult.riskLevel),
            color: _getColorForRiskLevel(fraudResult.riskLevel),
          ),
          const SizedBox(width: 8),
          Text(
            _getTitleForRiskLevel(fraudResult.riskLevel),
            style: TextStyle(
              color: _getColorForRiskLevel(fraudResult.riskLevel),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getDescriptionForRiskLevel(fraudResult.riskLevel)),
          const SizedBox(height: 16),
          if (fraudResult.riskFactors.isNotEmpty) ...[
            const Text(
              'Tespit edilen risk faktörleri:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...fraudResult.riskFactors.take(5).map((factor) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _translateRiskFactor(factor),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
            if (fraudResult.riskFactors.length > 5)
              Text(
                '+ ${fraudResult.riskFactors.length - 5} diğer faktör',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
          const SizedBox(height: 16),
          if (fraudResult.recommendedAction != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _translateRecommendedAction(fraudResult.recommendedAction!),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        if (!fraudResult.shouldBlock && onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('İptal'),
          ),
        if (!fraudResult.shouldBlock && onProceed != null)
          ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getColorForRiskLevel(fraudResult.riskLevel),
            ),
            child: Text(
              fraudResult.riskLevel == FraudRiskLevel.high
                  ? 'Yine de Devam Et'
                  : 'Devam Et',
            ),
          ),
        if (fraudResult.shouldBlock)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Tamam'),
          ),
      ],
    );
  }

  IconData _getIconForRiskLevel(FraudRiskLevel level) {
    switch (level) {
      case FraudRiskLevel.low:
        return Icons.info;
      case FraudRiskLevel.medium:
        return Icons.warning_amber;
      case FraudRiskLevel.high:
        return Icons.warning;
      case FraudRiskLevel.critical:
        return Icons.error;
    }
  }

  Color _getColorForRiskLevel(FraudRiskLevel level) {
    switch (level) {
      case FraudRiskLevel.low:
        return Colors.blue;
      case FraudRiskLevel.medium:
        return Colors.orange;
      case FraudRiskLevel.high:
        return Colors.red.shade600;
      case FraudRiskLevel.critical:
        return Colors.red.shade800;
    }
  }

  String _getTitleForRiskLevel(FraudRiskLevel level) {
    switch (level) {
      case FraudRiskLevel.low:
        return 'Güvenlik Bildirimi';
      case FraudRiskLevel.medium:
        return 'Güvenlik Uyarısı';
      case FraudRiskLevel.high:
        return 'Yüksek Risk Uyarısı';
      case FraudRiskLevel.critical:
        return 'İşlem Engellendi';
    }
  }

  String _getDescriptionForRiskLevel(FraudRiskLevel level) {
    switch (level) {
      case FraudRiskLevel.low:
        return 'Bu işlemde bazı güvenlik kontrolleri tespit edilmiştir. İşleminiz normal şekilde devam edebilir.';
      case FraudRiskLevel.medium:
        return 'Bu işlemde orta seviye güvenlik riskleri tespit edilmiştir. Lütfen işlem detaylarını kontrol edin.';
      case FraudRiskLevel.high:
        return 'Bu işlemde yüksek seviye güvenlik riskleri tespit edilmiştir. İşleminizi dikkatli bir şekilde gözden geçirin.';
      case FraudRiskLevel.critical:
        return 'Güvenlik nedeniyle bu işlem engellenmiştir. Lütfen müşteri hizmetleri ile iletişime geçin.';
    }
  }

  String _translateRiskFactor(String factor) {
    const translations = {
      'high_frequency_24h': 'Son 24 saatte çok sayıda işlem',
      'medium_frequency_24h': 'Son 24 saatte ortalama üzeri işlem',
      'high_frequency_7d': 'Son 7 günde çok sayıda işlem',
      'unusually_high_amount': 'Normalden çok yüksek tutar',
      'higher_than_average_amount': 'Ortalamanın üzerinde tutar',
      'new_user_high_amount': 'Yeni kullanıcı, yüksek tutar',
      'sudden_spending_increase': 'Ani harcama artışı',
      'rapid_purchases_10min': 'Son 10 dakikada hızlı alımlar',
      'quick_successive_purchases': 'Ardışık hızlı alımlar',
      'high_velocity_1hour': 'Son 1 saatte yüksek işlem hızı',
      'multiple_rapid_pairs': 'Çoklu hızlı işlem çiftleri',
      'amount_above_95th_percentile': 'Platformdaki işlemlerin %95\'inin üzerinde',
      'amount_above_90th_percentile': 'Platformdaki işlemlerin %90\'ının üzerinde',
      'amount_significantly_above_average': 'Ortalamadan önemli ölçüde yüksek',
      'round_number_pattern': 'Yuvarlak sayı deseni (test işlemi olabilir)',
      'suspicious_test_amount': 'Şüpheli test tutarı',
      'self_purchase_attempt': 'Kendi biletini satın alma girişimi',
      'multiple_purchases_same_seller': 'Aynı satıcıdan çoklu alım',
      'last_minute_purchase': 'Son dakika alımı',
      'past_event_purchase': 'Geçmiş etkinlik bileti alımı',
      'payment_method_change': 'Ödeme yöntemi değişikliği',
      'cash_payment_method': 'Nakit ödeme yöntemi',
      'unknown_payment_method': 'Bilinmeyen ödeme yöntemi',
      'unusual_hour_purchase': 'Sıradışı saatlerde alım',
      'bot_like_regular_intervals': 'Bot benzeri düzenli aralıklar',
      'multiple_devices': 'Çoklu cihaz kullanımı',
      'private_ip_address': 'Özel IP adresi (VPN/Proxy olabilir)',
      'analysis_error': 'Analiz hatası',
      'history_analysis_error': 'Geçmiş analiz hatası',
      'velocity_analysis_error': 'Hız analiz hatası',
      'amount_analysis_error': 'Tutar analiz hatası',
      'ticket_analysis_error': 'Bilet analiz hatası',
      'payment_analysis_error': 'Ödeme analiz hatası',
      'time_analysis_error': 'Zaman analiz hatası',
      'device_analysis_error': 'Cihaz analiz hatası',
    };

    return translations[factor] ?? factor;
  }

  String _translateRecommendedAction(String action) {
    const translations = {
      'block_self_purchase': 'Kendi biletinizi satın alamazsınız',
      'block_transaction': 'İşlem güvenlik nedeniyle engellenmiştir',
      'manual_review_required': 'Manuel inceleme gereklidir',
      'additional_verification': 'Ek doğrulama gerekebilir',
      'proceed': 'İşleme devam edebilirsiniz',
    };

    return translations[action] ?? action;
  }

  /// Show fraud warning dialog
  static Future<bool?> show({
    required BuildContext context,
    required FraudDetectionResult fraudResult,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !fraudResult.shouldBlock,
      builder: (context) => FraudWarningDialog(
        fraudResult: fraudResult,
        onProceed: fraudResult.shouldBlock 
            ? null 
            : () => Navigator.of(context).pop(true),
        onCancel: fraudResult.shouldBlock 
            ? null 
            : () => Navigator.of(context).pop(false),
      ),
    );
  }
}
