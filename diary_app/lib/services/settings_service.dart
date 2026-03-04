import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyRestTimerDuration = 'rest_timer_duration';
  static const int _defaultDuration = 150; // 2 minutes 30 seconds

  // Singleton instance
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  Future<int> getRestTimerDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRestTimerDuration) ?? _defaultDuration;
  }

  Future<void> setRestTimerDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRestTimerDuration, seconds);
  }
}
