import 'package:eventease/core/constants/country_config.dart';

/// Resolves payment gateway and tax by user country.
class PaymentGatewayService {
  PaymentGatewayService._();

  static String gatewayForCountry(String? countryCode) =>
      CountryConfig.paymentGatewayForCountry(countryCode);

  static double calculateTax(double amount, String? countryCode) {
    final rate = CountryConfig.taxRateForCountry(countryCode);
    return amount * rate;
  }

  static PaymentBreakdown buildBreakdown({
    required double subtotal,
    required double platformFee,
    double discount = 0,
    String? countryCode,
  }) {
    final afterDiscount = subtotal - discount;
    final tax = calculateTax(afterDiscount + platformFee, countryCode);
    return PaymentBreakdown(
      subtotal: subtotal,
      discount: discount,
      platformFee: platformFee,
      tax: tax,
      total: afterDiscount + platformFee + tax,
      currency: CountryConfig.currencyForCountry(countryCode),
      gateway: gatewayForCountry(countryCode),
    );
  }
}

class PaymentBreakdown {
  final double subtotal;
  final double discount;
  final double platformFee;
  final double tax;
  final double total;
  final String currency;
  final String gateway;

  const PaymentBreakdown({
    required this.subtotal,
    required this.discount,
    required this.platformFee,
    required this.tax,
    required this.total,
    required this.currency,
    required this.gateway,
  });
}
