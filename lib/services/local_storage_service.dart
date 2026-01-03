import 'package:shared_preferences/shared_preferences.dart';


class LocalStorageService {
  static const String _onboardingKey = 'seen_onboarding';

  /// Save that user has seen the onboarding
  Future<void> setSeenOnboarding(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, seen);
  }

  /// Check if user has seen the onboarding
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
}
