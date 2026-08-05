import 'package:shared_preferences/shared_preferences.dart';

/// Хранение пользовательских настроек.
/// Расширяется: notification on/off, anchor IDs, custom hours, survival mode, etc.
class SettingsStorage {
  SettingsStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<SettingsStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsStorage(prefs);
  }

  // ---- Уведомления ----

  bool get notificationsEnabled => _prefs.getBool('notif_enabled') ?? true;
  Future<void> setNotificationsEnabled(bool v) =>
      _prefs.setBool('notif_enabled', v);

  String? get morningAnchorId => _prefs.getString('anchor_morning');
  Future<void> setMorningAnchor(String? id) async {
    if (id == null) {
      await _prefs.remove('anchor_morning');
    } else {
      await _prefs.setString('anchor_morning', id);
    }
  }

  String? get eveningAnchorId => _prefs.getString('anchor_evening');
  Future<void> setEveningAnchor(String? id) async {
    if (id == null) {
      await _prefs.remove('anchor_evening');
    } else {
      await _prefs.setString('anchor_evening', id);
    }
  }

  /// Час уведомления (0–23). null → используем час из anchor.suggestedHour.
  int? get morningHour => _prefs.getInt('hour_morning');
  Future<void> setMorningHour(int? h) async {
    if (h == null) {
      await _prefs.remove('hour_morning');
    } else {
      await _prefs.setInt('hour_morning', h);
    }
  }

  int? get eveningHour => _prefs.getInt('hour_evening');
  Future<void> setEveningHour(int? h) async {
    if (h == null) {
      await _prefs.remove('hour_evening');
    } else {
      await _prefs.setInt('hour_evening', h);
    }
  }

  // ---- Survival mode (короткие версии квестов) ----
  bool get survivalMode => _prefs.getBool('survival_mode') ?? false;
  Future<void> setSurvivalMode(bool v) => _prefs.setBool('survival_mode', v);

  // ---- Онбординг пройден ----
  bool get onboardingDone => _prefs.getBool('onboarding_done') ?? false;
  Future<void> setOnboardingDone(bool v) => _prefs.setBool('onboarding_done', v);

  // ---- Согласие на облачную расшифровку голоса ----
  //
  // Голосовое «Выговорись» — единственная функция, которая отправляет данные
  // за пределы устройства (аудио и расшифровка уходят в Azure OpenAI).
  // По умолчанию false: молчаливого согласия быть не может, аудитория уязвимая,
  // а пропуск онбординга не должен ничего разрешать.
  bool get cloudVoiceConsent => _prefs.getBool('cloud_voice_consent') ?? false;
  Future<void> setCloudVoiceConsent(bool v) =>
      _prefs.setBool('cloud_voice_consent', v);
}
