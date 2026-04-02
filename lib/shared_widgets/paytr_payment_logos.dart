import 'package:flutter/material.dart';

/// PayTR ödeme yöntemlerini gösteren widget
class PayTRPaymentLogos extends StatelessWidget {
  final PayTRLogoStyle style;
  final double? height;
  final EdgeInsets? margin;

  const PayTRPaymentLogos({
    super.key,
    this.style = PayTRLogoStyle.horizontal,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case PayTRLogoStyle.horizontal:
        return _buildHorizontalLogos();
      case PayTRLogoStyle.square:
        return _buildSquareLogos();
      case PayTRLogoStyle.allInOne:
        return _buildAllInOneLogo();
    }
  }

  Widget _buildHorizontalLogos() {
    return Container(
      margin: margin ?? const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          _buildLogo('assets/images/paytr/Dikdortgen/dikdortgen-logo-paytr.jpg'),
          _buildLogo('assets/images/paytr/Dikdortgen/dikdortgen-logo-visa.jpg'),
          _buildLogo('assets/images/paytr/Dikdortgen/dikdortgen-logo-mastercard.jpg'),
          _buildLogo('assets/images/paytr/Dikdortgen/dikdortgen-logo-troy.jpg'),
          _buildLogo('assets/images/paytr/Dikdortgen/dikdortgen-logo-masterpass.jpg'),
        ],
      ),
    );
  }

  Widget _buildSquareLogos() {
    return Container(
      margin: margin ?? const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          _buildLogo('assets/images/paytr/Kare/kare-logo-paytr.jpg'),
          _buildLogo('assets/images/paytr/Kare/kare-logo-visa.jpg'),
          _buildLogo('assets/images/paytr/Kare/kare-logo-mastercard.jpg'),
          _buildLogo('assets/images/paytr/Kare/kare-logo-troy.jpg'),
        ],
      ),
    );
  }

  Widget _buildAllInOneLogo() {
    return Container(
      margin: margin ?? const EdgeInsets.all(8.0),
      child: Image.asset(
        'assets/images/paytr/Tek Parca/tekparca-logolar-1.jpg',
        height: height ?? 60,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLogo(String assetPath) {
    return Image.asset(
      assetPath,
      height: height ?? 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height ?? 40,
          width: 60,
          color: Colors.grey.shade300,
          child: const Icon(Icons.payment, size: 20),
        );
      },
    );
  }
}

/// PayTR bankalar logoları widget'ı
class PayTRBankLogos extends StatelessWidget {
  final double? height;
  final EdgeInsets? margin;

  const PayTRBankLogos({
    super.key,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 4.0,
        runSpacing: 4.0,
        children: [
          _buildBankLogo('assets/images/paytr/Dikdortgen/bankalar/dikdortgen-logo-ziraat.jpg'),
          _buildBankLogo('assets/images/paytr/Dikdortgen/bankalar/dikdortgen-logo-axess.jpg'),
          _buildBankLogo('assets/images/paytr/Dikdortgen/bankalar/dikdortgen-logo-bonus.jpg'),
          _buildBankLogo('assets/images/paytr/Dikdortgen/bankalar/dikdortgen-logo-maximum.jpg'),
          _buildBankLogo('assets/images/paytr/Dikdortgen/bankalar/dikdortgen-logo-paraf.jpg'),
          _buildBankLogo('assets/images/paytr/Dikdortgen/bankalar/dikdortgen-logo-advantage.jpg'),
        ],
      ),
    );
  }

  Widget _buildBankLogo(String assetPath) {
    return Image.asset(
      assetPath,
      height: height ?? 30,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height ?? 30,
          width: 45,
          color: Colors.grey.shade300,
          child: const Icon(Icons.credit_card, size: 15),
        );
      },
    );
  }
}

enum PayTRLogoStyle {
  horizontal,
  square,
  allInOne,
}
