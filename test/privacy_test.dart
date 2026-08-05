import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volna/data/local/diary_storage.dart';
import 'package:volna/data/local/settings_storage.dart';
import 'package:volna/data/local/wipe.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Согласие на облачную расшифровку', () {
    test('по умолчанию не дано — молчаливого согласия быть не может', () async {
      final settings = await SettingsStorage.create();
      expect(settings.cloudVoiceConsent, isFalse);
    });

    test('пропуск онбординга ничего не разрешает', () async {
      final settings = await SettingsStorage.create();
      await settings.setOnboardingDone(true);
      expect(settings.cloudVoiceConsent, isFalse);
    });

    test('согласие даётся и отзывается', () async {
      final settings = await SettingsStorage.create();
      await settings.setCloudVoiceConsent(true);
      expect(settings.cloudVoiceConsent, isTrue);
      await settings.setCloudVoiceConsent(false);
      expect(settings.cloudVoiceConsent, isFalse);
    });
  });

  group('Удаление всех данных', () {
    test('стирает дневник, настройки и снимает уведомления', () async {
      final diary = await DiaryStorage.create();
      final settings = await SettingsStorage.create();

      await diary.add(
        DiaryEntry(
          id: '1',
          kind: DiaryKind.envelope,
          createdAt: DateTime(2026, 8, 4),
          payload: const {'thought': 'завтра я не справлюсь'},
        ),
      );
      await settings.setOnboardingDone(true);
      await settings.setCloudVoiceConsent(true);
      expect(diary.all(), hasLength(1));

      var cancelled = false;
      await wipeAllLocalData(
        cancelNotifications: () async => cancelled = true,
      );

      // Уведомления снимаются ДО очистки: иначе пуш придёт к стёртой записи.
      expect(cancelled, isTrue);

      final freshDiary = await DiaryStorage.create();
      final freshSettings = await SettingsStorage.create();
      expect(freshDiary.all(), isEmpty);
      expect(freshSettings.onboardingDone, isFalse);
      expect(freshSettings.cloudVoiceConsent, isFalse);
    });
  });
}
