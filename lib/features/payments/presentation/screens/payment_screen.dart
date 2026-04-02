// lib/features/payments/presentation/screens/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stubstreet/features/auth/domain/entities/user.dart';
import 'package:stubstreet/features/orders/domain/entities/order.dart';

class PaymentScreen extends ConsumerWidget {
  final Order order;
  final User buyer;
  final User seller;

  const PaymentScreen({
    super.key,
    required this.order,
    required this.buyer,
    required this.seller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Bilet Satın Al',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Güvenli ödeme ile biletinizi satın alın',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Ticket Information
              _buildTicketInfo(context),
              const SizedBox(height: 24),

              // Payment Section (Temporarily Disabled)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Payment processing is temporarily unavailable.\nPlease try again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Security Information
              _buildSecurityInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bilet Bilgileri',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Etkinlik',
              'Konsert Bileti',
            ), // This would come from ticket data
            _buildInfoRow('Tarih', '15 Kasım 2024'),
            _buildInfoRow('Satıcı', seller.fullName),
            _buildInfoRow('Teslimat', order.deliveryMethod.displayName),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Güvenli Ödeme',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ödemeniz PayTR tarafından güvenli bir şekilde işlenir. '
            'Kart bilgileriniz hiçbir zaman StubStreet sunucularında saklanmaz.',
            style: TextStyle(color: Colors.green.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Payment callbacks - minimal implementation
  // void _onPaymentSuccess(BuildContext context, WidgetRef ref) { ... }
  // void _onPaymentFailure(BuildContext context) { ... }
  // void _onPaymentCanceled(BuildContext context) { ... }
}
