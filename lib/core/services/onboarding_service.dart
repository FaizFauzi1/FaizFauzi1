import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _prefix = 'tutorial_';
  
  static Future<bool> isTutorialCompleted(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$tutorialId') ?? false;
  }

  static Future<void> markTutorialAsCompleted(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$tutorialId', true);
  }

  static Future<void> resetTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$tutorialId');
  }

  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }
}
