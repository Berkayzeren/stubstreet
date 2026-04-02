import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// PayTR test kartları ve bilgileri gösteren widget
class PayTRTestInfo extends StatelessWidget {
  const PayTRTestInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Image.asset(
            'assets/images/paytr/Kare/kare-logo-paytr.jpg',
            height: 30,
            width: 30,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.payment, color: Colors.orange);
            },
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('PayTR Test Kartları'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test kartları ile ödeme yapabilirsiniz:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTestCard(
              context,
              title: '✅ Başarılı Test Kartı',
              cardNumber: '4508 0345 0803 4509',
              cvv: '000',
              expiry: '12/2030',
              holderName: 'Test User',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildTestCard(
              context,
              title: '❌ Başarısız Test Kartı',
              cardNumber: '4508 0345 0803 4508',
              cvv: '000',
              expiry: '12/2030',
              holderName: 'Test User',
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'ℹ️ Test modunda gerçek para çekilmez.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '🔒 Tüm ödeme bilgileri PayTR güvenlik protokolleri ile korunur.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kapat'),
        ),
      ],
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String cardNumber,
    required String cvv,
    required String expiry,
    required String holderName,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: HSLColor.fromColor(color).withLightness(0.3).toColor(),
            ),
          ),
          const SizedBox(height: 8),
          _buildCopyableInfo(context, 'Kart No', cardNumber),
          _buildCopyableInfo(context, 'CVV', cvv),
          _buildCopyableInfo(context, 'Son Kullanma', expiry),
          _buildCopyableInfo(context, 'Ad Soyad', holderName),
        ],
      ),
    );
  }

  Widget _buildCopyableInfo(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child:       Row(
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label kopyalandı'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
}

/// PayTR test bilgilerini gösteren buton
class PayTRTestInfoButton extends StatelessWidget {
  const PayTRTestInfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const PayTRTestInfo(),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Test Kartları ve Bilgiler',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
