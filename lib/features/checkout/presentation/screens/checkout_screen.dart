// lib/features/checkout/presentation/screens/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/checkout_session.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../orders/domain/entities/order.dart' as order_entity;
import '../../../orders/presentation/screens/order_detail_screen.dart';
import '../providers/checkout_providers.dart';
import '../services/paytr_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'paytr_webview_screen.dart';
import '../widgets/paytr_test_info.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared_widgets/responsive_wrapper.dart';

/// Clean checkout screen without Stripe dependencies
class CheckoutScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  final User buyer;

  const CheckoutScreen({
    super.key,
    required this.ticket,
    required this.buyer,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  // CheckoutStatus _currentStatus = CheckoutStatus.initiated;
  bool _isProcessing = false;
  String? _errorMessage;
  String _selectedPaymentMethod = 'paytr';
  order_entity.DeliveryMethod _selectedDeliveryMethod = order_entity.DeliveryMethod.digital;
  bool _isPaytrTest = (dotenv.env['PAYTR_TEST_MODE'] ?? '1') == '1';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.payment,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Güvenli Ödeme'),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Güvenlik Badge'i
                _buildSecurityBadge(),
                const SizedBox(height: 16),
                
                // Ticket Summary
                _buildTicketSummary(),
                const SizedBox(height: 20),
                
                // Payment Method Selector
                _buildPaymentMethodSelector(),
                const SizedBox(height: 20),
                
                // Delivery Method Selector
                _buildDeliveryMethodSelector(),
                const SizedBox(height: 16),
                
                // PayTR Test Info
                if (_selectedPaymentMethod == 'paytr') 
                  const PayTRTestInfoButton(),
                
                const SizedBox(height: 20),
                
                // Error Message
                if (_errorMessage != null)
                  _buildErrorMessage(),
                
                const SizedBox(height: 20),
                
                // Payment Button
                _buildPaymentButton(),
                
                const SizedBox(height: 16),
                
                // Trust Indicators
                _buildTrustIndicators(),
                
                // Bottom spacing for better UX
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            color: Colors.green.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '256-bit SSL ile güvenli ödeme',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsivePadding.responsive(
          context,
          mobile: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.confirmation_number,
                    color: Colors.blue.shade600,
                    size: context.isDesktop ? 24 : (context.isTablet ? 22 : 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Bilet Özeti',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ticket.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Etkinlik Bileti',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildPriceRow('Bilet Fiyatı', widget.ticket.sellingPrice),
            const SizedBox(height: 8),
            _buildPriceRow('Hizmet Bedeli (%5)', widget.ticket.sellingPrice * 0.05),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(thickness: 1),
            ),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Toplam Tutar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '${(widget.ticket.sellingPrice * 1.05).toStringAsFixed(2)} TL',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
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

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} TL',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsivePadding.responsive(
          context,
          mobile: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: Colors.purple.shade600,
                    size: context.isDesktop ? 24 : (context.isTablet ? 22 : 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ödeme Yöntemi Seçin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // PayTR seçeneği
            _buildPaymentOption(
              'paytr',
              'PayTR - Güvenli Ödeme',
              'Kredi/Banka Kartı ile ödeme',
              Icons.payment,
              Colors.blue,
              [
                Row(
                  children: [
                    Icon(Icons.credit_card, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('Visa', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 8),
                    Icon(Icons.credit_card, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('MasterCard', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            
            if (_selectedPaymentMethod == 'paytr') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Modu Seçimi',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTestModeChip('Normal (Canlı)', !_isPaytrTest, () {
                            setState(() {
                              _isPaytrTest = false;
                            });
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTestModeChip('Test (Sandbox)', _isPaytrTest, () {
                            setState(() {
                              _isPaytrTest = true;
                            });
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Alternatif ödeme seçeneği
            _buildPaymentOption(
              'credit_card',
              'Diğer Ödeme Yöntemleri',
              'Yakında aktif olacak',
              Icons.more_horiz,
              Colors.grey,
              [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Yakında',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<Widget> additionalWidgets,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    final isDisabled = value == 'credit_card'; // Diğer ödeme yöntemleri henüz aktif değil
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: isDisabled ? null : () {
          setState(() {
            _selectedPaymentMethod = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: ResponsivePadding.responsive(
          context,
          mobile: 12.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withValues(alpha: 0.1)
                : isDisabled 
                  ? Colors.grey.shade50
                  : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : isDisabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDisabled 
                          ? Colors.grey.shade200
                          : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isDisabled 
                          ? Colors.grey.shade400
                          : color,
                      size: context.isDesktop ? 24 : (context.isTablet ? 22 : 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDisabled 
                                ? Colors.grey.shade500
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDisabled 
                                ? Colors.grey.shade400
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? color
                        : isDisabled
                          ? Colors.grey.shade400
                          : Colors.grey,
                  ),
                ],
              ),
              if (additionalWidgets.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: additionalWidgets,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestModeChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.blue.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.blue.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryMethodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: ResponsivePadding.responsive(
          context,
          mobile: 16.0,
          tablet: 20.0,
          desktop: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: Colors.green.shade600,
                    size: context.isDesktop ? 24 : (context.isTablet ? 22 : 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Teslimat Yöntemi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () {
                setState(() {
                  _selectedDeliveryMethod = order_entity.DeliveryMethod.digital;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: ResponsivePadding.responsive(
          context,
          mobile: 12.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
                decoration: BoxDecoration(
                  color: _selectedDeliveryMethod == order_entity.DeliveryMethod.digital 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDeliveryMethod == order_entity.DeliveryMethod.digital
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: _selectedDeliveryMethod == order_entity.DeliveryMethod.digital ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.cloud_download,
                        color: Colors.green.shade600,
                        size: context.isDesktop ? 24 : (context.isTablet ? 22 : 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dijital Teslimat',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Biletiniz anında e-posta adresinize gönderilecek',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _selectedDeliveryMethod == order_entity.DeliveryMethod.digital
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedDeliveryMethod == order_entity.DeliveryMethod.digital
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Dijital teslimat avantajları
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anında teslimat • Çevre dostu • Güvenli',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _isProcessing 
            ? null 
            : LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isProcessing 
            ? null 
            : [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _initiateCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isProcessing ? Colors.grey.shade300 : Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'İşleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: context.isDesktop ? 24 : (context.isTablet ? 22 : 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Güvenli Ödeme - ${(widget.ticket.sellingPrice * 1.05).toStringAsFixed(2)} TL',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            'Güvenli Ödeme Garantisi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTrustItem(Icons.security, 'SSL\nŞifreleme'),
              _buildTrustItem(Icons.verified_user, '3D Secure\nDoğrulama'),
              _buildTrustItem(Icons.support_agent, '7/24\nDestek'),
              _buildTrustItem(Icons.money_off, 'Para İade\nGarantisi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.green.shade600,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _initiateCheckout() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final checkoutService = ref.read(checkoutServiceProvider);
      final checkoutSession = await checkoutService.initiateCheckout(
        ticketId: widget.ticket.id,
        buyer: widget.buyer,
        paymentMethod: _selectedPaymentMethod,
        deliveryMethod: _selectedDeliveryMethod,
      );
      
      await _processPayment(checkoutSession);
    } catch (e) {
      setState(() {
        // _currentStatus = CheckoutStatus.failed;
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  Future<void> _processPayment(CheckoutSession session) async {
    try {
      if (_selectedPaymentMethod == 'paytr') {
        await _processPayTRPayment(session);
      } else {
        // Diğer ödeme yöntemleri için mock implementation
        await _processMockPayment(session);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ödeme işleminde hata oluştu: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processPayTRPayment(CheckoutSession session) async {
    try {
      final paytrService = PaytrService();
      
      // PayTR callback URL'lerini oluştur
      final baseUrl = 'https://device-streaming-70d2d53c.firebaseapp.com'; // TODO: Hosting URL
      final okUrl = '$baseUrl/payment-success?session_id=${session.id}';
      final failUrl = '$baseUrl/payment-failed?session_id=${session.id}';

      // PayTR için gerekli payload'ı hazırla
      final totalAmount = session.totalAmount;
      
      // Kullanıcı bilgilerini önceden al ve debug
      debugPrint('🔍 Getting user data for PayTR...');
      
      final userAddress = await _getUserAddress();
      debugPrint('📍 User Address: "$userAddress" (length: ${userAddress.length})');
      
      final userPhone = await _getUserPhone();
      debugPrint('📞 User Phone: "$userPhone" (length: ${userPhone.length})');
      
      final userName = widget.buyer.displayName.isNotEmpty 
          ? widget.buyer.displayName 
          : widget.buyer.email.split('@')[0];
      debugPrint('👤 User Name: "$userName" (length: ${userName.length})');

      // PayTR zorunlu alanları kontrol et ve hazırla
      final payload = {
        // PayTR zorunlu alanları
        'email': widget.buyer.email,
        'amount': totalAmount.toStringAsFixed(2),
        'currency': 'TL',
        'orderId': session.id,
        // IP sunucuda tespit edilecek
        'okUrl': okUrl,
        'failUrl': failUrl,
        
        // PayTR opsiyonel ama önerilen alanlar
        'installmentCount': '0',
        'testMode': _isPaytrTest ? '1' : '0',
        'paymentType': 'card',
        'non3d': '0',
        'clientLang': 'tr',
        'debugOn': '1',
        'maxInstallment': '0',
        
        // Kullanıcı bilgileri (GEÇİCİ SABİT DEĞERLER - TEST İÇİN)
        'userName': 'admin_user', // Türkçe karakter yok
        'userAddress': 'Istanbul, Turkey', // Türkçe karakter yok
        'userPhone': '05555555555',
        
        // Sepet bilgileri (ondalık fiyat formatı)
        'basket': [
          ['Concert Ticket', (session.ticketPrice).toStringAsFixed(2), '1'],
          ['Service Fee', (session.serviceFee).toStringAsFixed(2), '1'],
        ],
      };

      // Debug için payload'ı logla
      debugPrint('🔍 PayTR Payload Debug:');
      debugPrint('Email: ${payload['email']}');
      debugPrint('Amount: ${payload['amount']}');
      debugPrint('OrderId: ${payload['orderId']}');
      debugPrint('UserName: ${payload['userName']}');
      debugPrint('UserAddress: ${payload['userAddress']}');
      debugPrint('UserPhone: ${payload['userPhone']}');
      debugPrint('Basket: ${payload['basket']}');

      // PayTR token'ını al
      final paytrParams = await paytrService.initialize(payload);

      // PayTR WebView'ını aç
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaytrWebViewScreen(params: paytrParams),
            fullscreenDialog: true,
          ),
        );

        // WebView'dan dönen sonuçları işle
        if (result == 'success') {
          // Ödeme başarılı - callback zaten handle edilmiş olmalı
          // Order detail sayfasına yönlendir
          _handlePaymentSuccess(session);
        } else if (result == 'failed') {
          setState(() {
            _errorMessage = 'Ödeme işlemi başarısız oldu.';
            _isProcessing = false;
          });
        } else {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getPayTRErrorMessage(e);
        _isProcessing = false;
      });
    }
  }

  Future<void> _processMockPayment(CheckoutSession session) async {
    try {
      // Ödeme işlemi
      await Future.delayed(const Duration(seconds: 2));
      
      final order = await ref
          .read(checkoutServiceProvider)
          .confirmCheckout(
            checkoutSessionId: session.id,
            paymentIntentId: session.paymentIntentId!,
          );

      setState(() {
        _isProcessing = false;
      });

      // Navigate to order detail
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(
              orderId: order.id,
              showSuccessMessage: true,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Mock ödeme hatası: $e';
        _isProcessing = false;
      });
    }
  }

  void _handlePaymentSuccess(CheckoutSession session) {
    setState(() {
      _isProcessing = false;
    });

    // Wait for callback to complete and check for order ID
    _waitForOrderCreation(session.id);
  }

  void _waitForOrderCreation(String sessionId) async {
    // Poll for order creation (max 10 seconds)
    for (int i = 0; i < 20; i++) {
      try {
        final sessionDoc = await FirebaseFirestore.instance
            .collection('checkout_sessions')
            .doc(sessionId)
            .get();

        if (sessionDoc.exists) {
          final data = sessionDoc.data() as Map<String, dynamic>;
          final orderId = data['orderId'] as String?;
          
          if (orderId != null && mounted) {
            // Order was created, navigate to order detail
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(
                  orderId: orderId,
                  showSuccessMessage: true,
                ),
              ),
            );
            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking order creation: $e');
      }

      // Wait 500ms before next check
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // If we get here, order creation might have failed
    if (mounted) {
      setState(() {
        _errorMessage = 'Ödeme tamamlandı ancak sipariş oluşturulamadı. Lütfen destek ile iletişime geçin.';
        _isProcessing = false;
      });
    }
  }

  String _getPayTRErrorMessage(dynamic error) {
    final errorStr = error.toString();
    
    // PayTR Error prefix'ini kaldır
    if (errorStr.contains('PayTR Error:')) {
      return errorStr.replaceFirst('PayTR Error: ', '');
    }
    
    // Spesifik hata türlerini kontrol et
    if (errorStr.contains('401') || errorStr.contains('Kimlik doğrulama')) {
      return 'Oturum süreniz dolmuş olabilir. Lütfen çıkış yapıp tekrar giriş yapın.';
    } else if (errorStr.contains('500') || errorStr.contains('Sunucu hatası')) {
      return 'Sunucu geçici olarak kullanılamıyor. Lütfen birkaç dakika sonra tekrar deneyin.';
    } else if (errorStr.contains('Network error') || errorStr.contains('Ağ hatası')) {
      return 'İnternet bağlantısı sorunu. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
    } else if (errorStr.contains('timeout') || errorStr.contains('zaman aşımı')) {
      return 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
    } else if (errorStr.contains('Invalid') || errorStr.contains('Geçersiz')) {
      return 'Ödeme bilgileri geçersiz. Lütfen bilgileri kontrol edin.';
    } else if (errorStr.contains('PAYTR credentials missing')) {
      return 'Ödeme sistemi yapılandırma hatası. Lütfen müşteri hizmetleri ile iletişime geçin.';
    } else if (errorStr.contains('Missing required fields')) {
      return 'Eksik bilgi. Lütfen tüm alanları doldurun.';
    } else {
      return 'Ödeme işleminde beklenmeyen bir hata oluştu. Lütfen tekrar deneyin veya müşteri hizmetleri ile iletişime geçin.';
    }
  }

  Future<String> _getUserAddress() async {
    try {
      // Kullanıcı profilini al
      final profileAsyncValue = ref.read(userProfileProvider(widget.buyer.id));
      
      final address = profileAsyncValue.when(
        data: (profile) {
          if (profile.location != null && profile.location!.trim().isNotEmpty) {
            return profile.location!.trim();
          }
          return 'İstanbul, Türkiye'; // Daha spesifik varsayılan
        },
        loading: () => 'İstanbul, Türkiye',
        error: (_, __) => 'İstanbul, Türkiye',
      );
      
      // Minimum uzunluk kontrolü
      return address.length >= 5 ? address : 'İstanbul, Türkiye';
    } catch (e) {
      debugPrint('Error getting user address: $e');
      return 'İstanbul, Türkiye'; // Hata durumunda güvenli varsayılan
    }
  }

  Future<String> _getUserPhone() async {
    try {
      // Önce User nesnesinden telefon numarasını kontrol et
      if (widget.buyer.phoneNumber != null && widget.buyer.phoneNumber!.trim().isNotEmpty) {
        final phone = widget.buyer.phoneNumber!.trim();
        // Türkiye formatını kontrol et
        final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        if (RegExp(r'^(\+90|0)?[5][0-9]{9}$').hasMatch(cleanPhone)) {
          return cleanPhone.startsWith('0') ? cleanPhone : '0${cleanPhone.replaceFirst('+90', '')}';
        }
      }
      
      // Eğer yoksa UserProfile'dan al
      final profileAsyncValue = ref.read(userProfileProvider(widget.buyer.id));
      
      final phone = profileAsyncValue.when(
        data: (profile) {
          if (profile.phoneNumber != null && profile.phoneNumber!.trim().isNotEmpty) {
            final phone = profile.phoneNumber!.trim();
            final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
            if (RegExp(r'^(\+90|0)?[5][0-9]{9}$').hasMatch(cleanPhone)) {
              return cleanPhone.startsWith('0') ? cleanPhone : '0${cleanPhone.replaceFirst('+90', '')}';
            }
          }
          return '05555555555'; // Varsayılan test numarası
        },
        loading: () => '05555555555',
        error: (_, __) => '05555555555',
      );
      
      return phone;
    } catch (e) {
      debugPrint('Error getting user phone: $e');
      return '05555555555'; // Hata durumunda güvenli varsayılan
    }
  }

}
