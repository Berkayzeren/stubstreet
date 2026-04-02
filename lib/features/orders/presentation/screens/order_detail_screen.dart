// lib/features/orders/presentation/screens/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/order.dart';
import '../../../conversations/presentation/screens/firebase_chat_screen.dart';
import '../providers/order_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  final bool showSuccessMessage;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.showSuccessMessage = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orderAsyncValue = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Detayı'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: orderAsyncValue.when(
        data: (Order? order) {
          if (order == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sipariş bulunamadı'),
                  SizedBox(height: 8),
                  Text('Bu sipariş mevcut değil veya silinmiş olabilir.'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success message if needed
                if (showSuccessMessage) ...[
                  _buildSuccessCard(context),
                  const SizedBox(height: 20),
                ],

                // Order status
                _buildStatusCard(context, order),
                const SizedBox(height: 20),

                // Order details
                _buildOrderDetailsCard(context, order),
                const SizedBox(height: 20),

                // Payment information
                _buildPaymentCard(context, order),
                const SizedBox(height: 20),

                // Delivery information
                _buildDeliveryCard(context, order),
                const SizedBox(height: 20),

                // Actions
                _buildActionsCard(context, order),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ödeme Başarılı!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Biletiniz başarıyla satın alındı. E-posta adresinize onay gönderildi.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipariş Durumu',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(order.status),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sipariş ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)} tarihinde oluşturuldu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(BuildContext context, Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipariş Detayları',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Sipariş No', order.id),
            _buildDetailRow('Satıcı', order.sellerName),
            _buildDetailRow('Alıcı', order.buyerName),
            _buildDetailRow('Teslimat', order.deliveryMethod.displayName),
            if (order.notes != null && order.notes!.isNotEmpty)
              _buildDetailRow('Notlar', order.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ödeme Bilgileri',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow(
              context,
              'Bilet Fiyatı',
              order.ticketPrice,
              order.currency,
            ),
            _buildPaymentRow(
              context,
              'Hizmet Bedeli',
              order.serviceFee,
              order.currency,
            ),
            const Divider(),
            _buildPaymentRow(
              context,
              'Toplam',
              order.totalAmount,
              order.currency,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teslimat Bilgileri',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(order.deliveryMethod.icon, color: theme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.deliveryMethod.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDeliveryDescription(order.deliveryMethod),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'İşlemler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Show QR Code button
            ElevatedButton.icon(
              onPressed: () {
                _showQRCode(context);
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('QR Kodunu Göster'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 12),

            // Download ticket button
            OutlinedButton.icon(
              onPressed: () {
                _downloadTicket(context);
              },
              icon: const Icon(Icons.download),
              label: const Text('Bileti İndir'),
            ),

            const SizedBox(height: 12),

            // Contact seller button
            OutlinedButton.icon(
              onPressed: () {
                _contactSeller(context, order);
              },
              icon: const Icon(Icons.message),
              label: const Text('Satıcıyla İletişim'),
            ),

            // Cancel order button (if applicable)
            if (order.canBeCancelled) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _showCancelDialog(context, order);
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Siparişi İptal Et'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Widget _buildPaymentRow(
    BuildContext context,
    String label,
    double amount,
    String currency, {
    bool isTotal = false,
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
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} $currency',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? theme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey;
      case OrderStatus.disputed:
        return Colors.red;
    }
  }

  String _getDeliveryDescription(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.digital:
        return 'Bilet QR kodunuz aşağıdaki butondan görüntülenebilir';
      case DeliveryMethod.mail:
        return 'Fiziki bilet posta ile gönderilecek';
      case DeliveryMethod.pickup:
        return 'Bileti satıcıdan teslim alacaksınız';
      case DeliveryMethod.meetup:
        return 'Satıcı ile buluşma noktasında teslim alacaksınız';
    }
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Kod'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code,
                  size: 120,
                  color: Color(0xFF757575), // Colors.grey.shade600 equivalent
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu QR kodu etkinlik girişinde gösteriniz',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _downloadTicket(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bilet indirme özelliği yakında eklenecek'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _contactSeller(BuildContext context, Order order) {
    // Satıcı ile mesajlaşma ekranına yönlendir
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FirebaseChatScreen(
          conversationId: '${order.buyerId}_${order.sellerId}',
          otherUserId: order.sellerId,
          otherUserName: order.sellerName,
          otherUserAvatarUrl: (order.sellerAvatarUrl?.isNotEmpty ?? false)
              ? order.sellerAvatarUrl
              : null,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi İptal Et'),
        content: const Text(
          'Bu siparişi iptal etmek istediğinizden emin misiniz? '
          'İptal edilen siparişler geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sipariş iptal özelliği yakında eklenecek'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }

}
