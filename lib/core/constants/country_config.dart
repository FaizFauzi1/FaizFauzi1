/// Country configuration for EventEase multi-country support.
class CountryConfig {
  CountryConfig._();

  static const String defaultCountryCode = 'MY';

  static const Map<String, CountryInfo> supported = {
    'MY': CountryInfo(
      code: 'MY',
      name: 'Malaysia',
      currencyCode: 'MYR',
      currencySymbol: 'RM',
      phonePrefix: '+60',
      taxRate: 0.08,
      paymentGateway: 'billplz',
    ),
    'SG': CountryInfo(
      code: 'SG',
      name: 'Singapore',
      currencyCode: 'SGD',
      currencySymbol: 'S\$',
      phonePrefix: '+65',
      taxRate: 0.09,
      paymentGateway: 'xendit',
    ),
    'ID': CountryInfo(
      code: 'ID',
      name: 'Indonesia',
      currencyCode: 'IDR',
      currencySymbol: 'Rp',
      phonePrefix: '+62',
      taxRate: 0.11,
      paymentGateway: 'xendit',
    ),
  };

  static CountryInfo get defaultCountry =>
      supported[defaultCountryCode]!;

  static CountryInfo? forCode(String? code) =>
      code != null ? supported[code.toUpperCase()] : null;

  static String currencyForCountry(String? countryCode) =>
      forCode(countryCode)?.currencyCode ?? defaultCountry.currencyCode;

  static String paymentGatewayForCountry(String? countryCode) =>
      forCode(countryCode)?.paymentGateway ?? defaultCountry.paymentGateway;

  static double taxRateForCountry(String? countryCode) =>
      forCode(countryCode)?.taxRate ?? defaultCountry.taxRate;
}

class CountryInfo {
  final String code;
  final String name;
  final String currencyCode;
  final String currencySymbol;
  final String phonePrefix;
  final double taxRate;
  final String paymentGateway;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.phonePrefix,
    required this.taxRate,
    required this.paymentGateway,
  });
}
