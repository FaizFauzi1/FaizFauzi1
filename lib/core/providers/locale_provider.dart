import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists app UI language and exposes a [Locale] for [MaterialApp].
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_locale_code';

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ms'),
    Locale('zh', 'CN'),
  ];

  Locale _locale = supportedLocales.first;

  Locale get locale => _locale;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey) ?? 'en';
    _locale = codeToLocale(code);
    notifyListeners();
  }

  static Locale codeToLocale(String code) {
    switch (code) {
      case 'ms':
        return const Locale('ms');
      case 'zh':
        return const Locale('zh', 'CN');
      default:
        return const Locale('en');
    }
  }

  static String localeToCode(Locale l) {
    if (l.languageCode == 'zh') return 'zh';
    if (l.languageCode == 'ms') return 'ms';
    return 'en';
  }

  /// Matches labels used in vendor/customer settings pickers.
  static String localeToDisplayName(Locale l) {
    switch (l.languageCode) {
      case 'ms':
        return 'Bahasa Malaysia';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }

  static String displayNameToCode(String display) {
    if (display.contains('Bahasa')) return 'ms';
    if (display == '中文') return 'zh';
    return 'en';
  }

  Future<void> setLocaleByCode(String code) async {
    _locale = codeToLocale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, localeToCode(_locale));
    notifyListeners();
  }
}
