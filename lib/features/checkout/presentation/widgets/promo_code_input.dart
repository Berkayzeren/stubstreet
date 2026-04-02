// lib/features/checkout/presentation/widgets/promo_code_input.dart

import 'package:flutter/material.dart';

class PromoCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final Function() onApply;
  final double discount;
  final bool isLoading;

  const PromoCodeInput({
    super.key,
    required this.controller,
    required this.onApply,
    required this.discount,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promosyon Kodu',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.card_giftcard, color: theme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Kodunuzu girin',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Uygula'),
                ),
              ],
            ),
          ),
        ),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${discount.toStringAsFixed(2)} TL indirim uygulandı!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
