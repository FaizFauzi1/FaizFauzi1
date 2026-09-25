import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:eventease/core/constants/country_config.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:eventease/features/location/data/models/country.dart';

/// Manages the user's selected country and syncs currency preferences.
class CountryProvider extends ChangeNotifier {
  static const _prefKey = 'user_country_code';

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Country> _countries = [];
  String _selectedCountryCode = CountryConfig.defaultCountryCode;
  bool _isLoading = false;
  String? _error;

  List<Country> get countries => _countries;
  String get selectedCountryCode => _selectedCountryCode;
  CountryInfo get selectedCountry =>
      CountryConfig.forCode(_selectedCountryCode) ??
      CountryConfig.defaultCountry;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCountryCode =
        prefs.getString(_prefKey) ?? CountryConfig.defaultCountryCode;
    await fetchCountries();
    await CurrencyFormatter.updateForCountry(_selectedCountryCode);
    notifyListeners();
  }

  Future<void> fetchCountries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('countries')
          .select()
          .eq('is_active', true)
          .order('name');

      _countries = (response as List)
          .map((e) => Country.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to static config when DB unavailable
      _countries = CountryConfig.supported.values
          .map((info) => Country(
                id: info.code,
                name: info.name,
                code: info.code,
              ))
          .toList();
      _error = 'Using offline country list';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCountry(String countryCode) async {
    final code = countryCode.toUpperCase();
    if (!CountryConfig.supported.containsKey(code)) return;

    _selectedCountryCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
    await CurrencyFormatter.updateForCountry(code);
    notifyListeners();
  }

  /// Persist country to the authenticated user's profile tables.
  Future<void> syncToProfile({
    required String userId,
    required String role,
  }) async {
    final code = _selectedCountryCode;
    try {
      await _supabase
          .from('users')
          .update({'country_code': code}).eq('id', userId);

      final roleTable = switch (role) {
        'vendor' => 'vendor_user',
        'admin' || 'super_admin' => 'admin_user',
        _ => 'customer_user',
      };

      await _supabase
          .from(roleTable)
          .update({'country_code': code}).eq('id', userId);

      if (role == 'vendor') {
        await _supabase.from('vendor_profiles').update({
          'country_code': code,
          'country': selectedCountry.name,
        }).eq('user_id', userId);
      }
    } catch (e) {
      debugPrint('CountryProvider.syncToProfile error: $e');
    }
  }

  Future<void> loadFromProfile(String userId, String role) async {
    try {
      final roleTable = switch (role) {
        'vendor' => 'vendor_user',
        'admin' || 'super_admin' => 'admin_user',
        _ => 'customer_user',
      };

      final response = await _supabase
          .from(roleTable)
          .select('country_code')
          .eq('id', userId)
          .maybeSingle();

      final code = response?['country_code'] as String?;
      if (code != null && CountryConfig.supported.containsKey(code)) {
        await setCountry(code);
      }
    } catch (e) {
      debugPrint('CountryProvider.loadFromProfile error: $e');
    }
  }
}
