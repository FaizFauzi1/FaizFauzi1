import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eventease/core/constants/country_config.dart';

class CurrencyFormatter {
  static const String _prefKey = 'vendor_settings_currency';
  static const String _countryPrefKey = 'user_country_code';
  static String _currentCurrency = 'MYR';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final countryCode =
        prefs.getString(_countryPrefKey) ?? CountryConfig.defaultCountryCode;
    _currentCurrency = prefs.getString(_prefKey) ??
        CountryConfig.currencyForCountry(countryCode);
  }

  static Future<void> updateCurrency(String newCurrency) async {
    _currentCurrency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newCurrency);
  }

  static Future<void> updateForCountry(String countryCode) async {
    final currency = CountryConfig.currencyForCountry(countryCode);
    _currentCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryPrefKey, countryCode.toUpperCase());
    await prefs.setString(_prefKey, currency);
  }

  static String get currentCurrency => _currentCurrency;

  static String format(dynamic amount) {
    if (amount == null) return '';
    double value = 0.0;
    if (amount is double) {
      value = amount;
    } else if (amount is int) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }

    return NumberFormat.simpleCurrency(name: _currentCurrency).format(value);
  }

  static String get symbol =>
      NumberFormat.simpleCurrency(name: _currentCurrency).currencySymbol;
}
