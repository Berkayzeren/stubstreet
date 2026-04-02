// lib/features/checkout/domain/entities/payment_method.dart

enum PaymentMethodType {
  creditCard,
  debitCard,
  applePay,
  googlePay,
  paypal,
  bankTransfer,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get displayName {
    switch (this) {
      case PaymentMethodType.creditCard:
        return 'Kredi Kartı';
      case PaymentMethodType.debitCard:
        return 'Banka Kartı';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.googlePay:
        return 'Google Pay';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.bankTransfer:
        return 'Banka Havalesi';
    }
  }

  String get iconPath {
    switch (this) {
      case PaymentMethodType.creditCard:
        return 'assets/icons/credit_card.png';
      case PaymentMethodType.debitCard:
        return 'assets/icons/debit_card.png';
      case PaymentMethodType.applePay:
        return 'assets/icons/apple_pay.png';
      case PaymentMethodType.googlePay:
        return 'assets/icons/google_pay.png';
      case PaymentMethodType.paypal:
        return 'assets/icons/paypal.png';
      case PaymentMethodType.bankTransfer:
        return 'assets/icons/bank_transfer.png';
    }
  }
}
