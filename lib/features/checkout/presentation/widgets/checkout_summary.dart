// lib/features/checkout/presentation/widgets/checkout_summary.dart

import 'package:flutter/material.dart';

class CheckoutSummary extends StatelessWidget {
  final double subtotal;
  final double serviceFee;
  final double discount;
  final double total;
  final String currency;

  const CheckoutSummary({
    super.key,
    required this.subtotal,
    required this.serviceFee,
    required this.discount,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ödeme Özeti',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Subtotal
            _buildSummaryRow(context, 'Ara Toplam', subtotal, currency),

            // Service fee
            _buildSummaryRow(context, 'Hizmet Bedeli', serviceFee, currency),

            // Discount (if any)
            if (discount > 0) ...[
              _buildSummaryRow(
                context,
                'İndirim',
                -discount,
                currency,
                color: Colors.green,
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),

            // Total
            _buildSummaryRow(context, 'Toplam', total, currency, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double amount,
    String currency, {
    bool isTotal = false,
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            '${amount >= 0 ? '' : '-'}${amount.abs().toStringAsFixed(2)} $currency',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isTotal ? theme.primaryColor : null),
            ),
          ),
        ],
      ),
    );
  }
}
