import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsService', () {
    late SettingsService settingsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
    });

    test('getRestTimerDuration should return default value if not set', () async {
      final duration = await settingsService.getRestTimerDuration();
      expect(duration, 150);
    });

    test('getRestTimerDuration should return saved value', () async {
      SharedPreferences.setMockInitialValues({'rest_timer_duration': 60});
      final duration = await settingsService.getRestTimerDuration();
      expect(duration, 60);
    });

    test('setRestTimerDuration should save value', () async {
      await settingsService.setRestTimerDuration(90);
      final duration = await settingsService.getRestTimerDuration();
      expect(duration, 90);
    });
  });
}
