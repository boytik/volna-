import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/content/anchor_options.dart';
import '../data/content/notification_phrases.dart';
import '../data/local/settings_storage.dart';

/// Локальные пуш-уведомления.
/// Принципы:
/// — никогда не угрожаем, не торопим,
/// — все пуши выключаются одним переключателем,
/// — для системных уведомлений (re-open конверта) — отдельный канал, не зависит от настройки утро/вечер.
class NotificationService {
  NotificationService(this._settings);

  static const _channelDaily = 'daily_quests';
  static const _channelEnvelope = 'envelope_reopen';
  static const _idMorning = 1001;
  static const _idEvening = 1002;
  static const _idSoftReminder = 1003;
  static const _idEnvelopeBase = 2000;

  final SettingsStorage _settings;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // На вебе flutter_local_notifications + flutter_timezone падают —
    // безопасно отключаем уведомления.
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      tz_data.initializeTimeZones();
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      debugPrint('NotificationService: timezone fallback: $e');
    }

    try {
      const initSettings = InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(initSettings);
    } catch (e) {
      debugPrint('NotificationService: init plugin failed: $e');
    }

    _initialized = true;
  }

  /// Запросить у пользователя разрешение на уведомления.
  /// Возвращает true, если выдано.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final iOS = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  /// Перезапланировать все ежедневные уведомления исходя из текущих настроек.
  /// Безопасно вызывать многократно.
  Future<void> rescheduleAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(_idMorning);
      await _plugin.cancel(_idEvening);
      await _plugin.cancel(_idSoftReminder);
    } catch (e) {
      debugPrint('NotificationService: cancel failed: $e');
      return;
    }

    if (!_settings.notificationsEnabled) return;

    final morningHour = _settings.morningHour ??
        _anchorById(morningAnchors, _settings.morningAnchorId)?.suggestedHour ??
        8;
    final eveningHour = _settings.eveningHour ??
        _anchorById(eveningAnchors, _settings.eveningAnchorId)?.suggestedHour ??
        21;

    final morningCopy = _composeMorning();
    final eveningCopy = _composeEvening();

    await _scheduleDaily(
      id: _idMorning,
      hour: morningHour,
      minute: 0,
      title: morningCopy.title,
      body: morningCopy.body,
    );

    await _scheduleDaily(
      id: _idEvening,
      hour: eveningHour,
      minute: 0,
      title: eveningCopy.title,
      body: eveningCopy.body,
    );

    // Тихое напоминание — «на случай если ничего не сделал». Раньше оно
    // планировалось безусловно и в 21:30, то есть человек, выполнивший
    // вечерний шаг в 21:05, через 25 минут получал упрёк. Теперь ставим его
    // только если день пуст, и не ближе часа к вечернему пушу.
    final softHour = _softReminderHour(eveningHour);
    if (softHour != null && _isDayEmpty()) {
      await _scheduleDaily(
        id: _idSoftReminder,
        hour: softHour,
        minute: 30,
        title: softReminder.title,
        body: softReminder.body,
      );
    }
  }

  /// Час тихого напоминания или null, если его некуда поставить.
  /// Держим минимум час от вечернего пуша и не выходим за 22:30.
  int? _softReminderHour(int eveningHour) {
    const preferred = 21;
    if ((preferred - eveningHour).abs() >= 1) return preferred;
    final shifted = eveningHour + 1;
    return shifted <= 22 ? shifted : null;
  }

  /// Сделал ли человек хоть что-то сегодня.
  /// Уведомление планируется на сутки вперёд, поэтому это оценка на момент
  /// планирования; rescheduleAll вызывается после каждого выполненного шага.
  bool _isDayEmpty() => _isDayEmptyToday?.call() ?? true;

  /// Подставляется из main — сервис не должен знать про QuestStorage.
  bool Function()? _isDayEmptyToday;
  // ignore: use_setters_to_change_properties
  void bindActivityCheck(bool Function() isDayEmpty) =>
      _isDayEmptyToday = isDayEmpty;

  /// Запланировать переоткрытие конверта тревоги через [after].
  Future<int> scheduleEnvelopeReopen({required Duration after}) async {
    if (kIsWeb) return -1;
    if (!_initialized) return -1;
    final id = _idEnvelopeBase +
        DateTime.now().millisecondsSinceEpoch.remainder(900000);

    final scheduled = tz.TZDateTime.now(tz.local).add(after);
    final ok = await _schedule(
      id: id,
      title: envelopeReopen.title,
      body: envelopeReopen.body,
      at: scheduled,
      details: _envelopeDetails(),
      payload: 'envelope',
    );
    return ok ? id : -1;
  }

  Future<void> cancelEnvelope(int id) async => _plugin.cancel(id);

  /// Снять вообще все запланированные уведомления.
  /// Нужно при удалении данных: иначе пуш придёт к стёртой записи.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: cancelAll failed: $e');
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _schedule(
      id: id,
      title: title,
      body: body,
      at: scheduled,
      details: _dailyDetails(),
      repeatDaily: true,
    );
  }

  /// Планирование с фолбэком.
  ///
  /// Android 12+ требует отдельного разрешения на точные будильники, и если
  /// пользователь его не дал, `exactAllowWhileIdle` бросает PlatformException.
  /// Для напоминаний точность до минуты не нужна — молча падаем на неточный
  /// режим, чтобы напоминания просто работали.
  Future<bool> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required NotificationDetails details,
    bool repeatDaily = false,
    String? payload,
  }) async {
    for (final mode in [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          at,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
          payload: payload,
        );
        return true;
      } catch (e) {
        debugPrint('NotificationService: schedule($id, $mode) failed: $e');
      }
    }
    return false;
  }

  NotificationDetails _dailyDetails() => const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _channelDaily,
          'Ежедневные шаги',
          channelDescription: 'Утреннее и вечернее напоминание',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  NotificationDetails _envelopeDetails() => const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          _channelEnvelope,
          'Конверт тревоги',
          channelDescription: 'Возврат к отложенным мыслям',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  AnchorOption? _anchorById(List<AnchorOption> list, String? id) {
    if (id == null) return null;
    for (final a in list) {
      if (a.id == id) return a;
    }
    return null;
  }

  NotificationCopy _composeMorning() {
    final anchor = _anchorById(morningAnchors, _settings.morningAnchorId);
    if (anchor != null) {
      final tpl = morningWithAnchor[
          math.Random().nextInt(morningWithAnchor.length)];
      return NotificationCopy(
        title: 'Утренний шаг',
        body: tpl.replaceAll('{anchor}', anchor.notificationCopy),
      );
    }
    return morningPlain[math.Random().nextInt(morningPlain.length)];
  }

  NotificationCopy _composeEvening() {
    final anchor = _anchorById(eveningAnchors, _settings.eveningAnchorId);
    if (anchor != null) {
      final tpl = eveningWithAnchor[
          math.Random().nextInt(eveningWithAnchor.length)];
      return NotificationCopy(
        title: 'Вечерний шаг',
        body: tpl.replaceAll('{anchor}', anchor.notificationCopy),
      );
    }
    return eveningPlain[math.Random().nextInt(eveningPlain.length)];
  }
}
