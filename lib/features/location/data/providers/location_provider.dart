import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/region.dart';
import '../models/city.dart';
import '../models/country.dart';
import 'package:eventease/core/constants/country_config.dart';

class LocationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Region> _regions = [];
  List<City> _cities = [];
  List<Country> _countries = [];
  String? _selectedCountryCode;

  Map<String, List<City>> _citiesCache = {};

  bool _isLoading = false;
  String? _error;

  List<Region> get regions => _regions;
  List<Country> get countries => _countries;
  String? get selectedCountryCode => _selectedCountryCode;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCountries() async {
    try {
      final response = await _supabase
          .from('countries')
          .select()
          .eq('is_active', true)
          .order('name');

      _countries = (response as List).map((e) => Country.fromJson(e)).toList();
    } catch (e) {
      _countries = CountryConfig.supported.values
          .map((info) => Country(id: info.code, name: info.name, code: info.code))
          .toList();
    }
    notifyListeners();
  }

  /// Fetch active regions, optionally filtered by country code.
  Future<void> fetchRegions({String? countryCode}) async {
    _selectedCountryCode = countryCode ?? _selectedCountryCode;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var query = _supabase.from('regions').select().eq('is_active', true);
      if (_selectedCountryCode != null) {
        query = query.eq('country_code', _selectedCountryCode!);
      }
      final response = await query.order('name', ascending: true);

      _regions = (response as List).map((e) => Region.fromJson(e)).toList();
    } catch (e) {
      _error = 'Failed to load regions: $e';
      print('LocationProvider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch cities for a specific region
  Future<List<City>> fetchCities(String regionId) async {
    // Return cached if available
    if (_citiesCache.containsKey(regionId)) {
      return _citiesCache[regionId]!;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('cities')
          .select()
          .eq('region_id', regionId)
          .eq('is_active', true)
          .order('name', ascending: true);

      final cities = (response as List).map((e) => City.fromJson(e)).toList();
      _citiesCache[regionId] = cities;
      return cities;
    } catch (e) {
      print('LocationProvider City Error: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get city name by ID (helper)
  Future<String?> getCityName(String cityId) async {
     try {
       final response = await _supabase.from('cities').select('name').eq('id', cityId).single();
       return response['name'] as String?;
     } catch(e) {
       return null;
     }
  }
  
    /// Get region name by ID (helper)
  Future<String?> getRegionName(String regionId) async {
     try {
       final response = await _supabase.from('regions').select('name').eq('id', regionId).single();
       return response['name'] as String?;
     } catch(e) {
       return null;
     }
  }
}
