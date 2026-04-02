// lib/features/checkout/presentation/widgets/payment_method_selector.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../domain/entities/payment_method.dart';
import '../../../../shared_widgets/paytr_payment_logos.dart';

class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethodType selectedMethod;
  final Function(PaymentMethodType) onMethodChanged;
  final bool showApplePay;
  final bool showGooglePay;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.showApplePay = false,
    this.showGooglePay = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ödeme Yöntemi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Credit Card option with PayTR
        _buildPaymentOption(
          context: context,
          method: PaymentMethodType.creditCard,
          title: 'Kredi/Banka Kartı',
          subtitle: 'PayTR ile güvenli ödeme',
          icon: Icons.credit_card,
          iconColor: Colors.blue,
          showPayTRLogos: true,
        ),

        // Apple Pay option
        if (showApplePay) ...[
          const SizedBox(height: 8),
          _buildPaymentOption(
            context: context,
            method: PaymentMethodType.applePay,
            title: 'Apple Pay',
            subtitle: 'Touch ID veya Face ID ile öde',
            icon: Icons.apple,
            iconColor: Colors.black,
          ),
        ],

        // Google Pay option
        if (showGooglePay) ...[
          const SizedBox(height: 8),
          _buildPaymentOption(
            context: context,
            method: PaymentMethodType.googlePay,
            title: 'Google Pay',
            subtitle: 'Hızlı ve güvenli ödeme',
            icon: Icons.g_mobiledata,
            iconColor: Colors.green,
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required PaymentMethodType method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    bool showPayTRLogos = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedMethod == method;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        // InkWell ile tıklanabilir hale getiriyoruz
        onTap: () => onMethodChanged(method),
        child: ListTile(
          leading: Radio<PaymentMethodType>.adaptive(
            // adaptive kullanarak platforma özgü görünüm sağlıyoruz
            value: method,
            groupValue: selectedMethod,
            onChanged: (value) {
              if (value != null) {
                onMethodChanged(value);
              }
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (showPayTRLogos) ...[
                    const SizedBox(height: 8),
                    const PayTRPaymentLogos(
                      style: PayTRLogoStyle.horizontal,
                      height: 25,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        selected: isSelected,
        selectedTileColor: theme.primaryColor.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}
