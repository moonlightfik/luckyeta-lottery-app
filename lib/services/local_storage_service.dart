import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  /// Save that the onboarding has been seen
  Future<void> setSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', value);
  }

  /// Check if onboarding was already seen
  Future<bool> getSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') ?? false;
  }

  /// Alias helper (always returns a bool)
  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') ?? false;
  }
}
