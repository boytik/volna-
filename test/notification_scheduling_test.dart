// Логика планирования уведомлений — на моке method-канала плагина.
//
// iOS без выданного разрешения тихо не кладёт уведомление в системный центр,
// поэтому «настоящий» pending на симуляторе проверить нельзя без нажатия
// системного диалога. Здесь важна не доставка, а наша логика: при включённых
// напоминаниях rescheduleAll обязан вызвать zonedSchedule для утра (1001) и
// вечера (1002), при выключенных — только снять расписание и ничего не ставить,
// а тихое напоминание (1003) появляться только когда день пуст.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart'
    show FlutterLocalNotificationsPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:volna/data/local/settings_storage.dart';
import 'package:volna/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notifChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const tzChannel = MethodChannel('flutter_timezone');
  late List<MethodCall> calls;

  int idOf(Object? args) =>
      (args is Map ? args['id'] : args) as int;

  Set<int> scheduledIds() => calls
      .where((c) => c.method == 'zonedSchedule')
      .map((c) => idOf(c.arguments))
      .toSet();

  Set<int> canceledIds() => calls
      .where((c) => c.method == 'cancel')
      .map((c) => idOf(c.arguments))
      .toSet();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // Главный класс диспатчит через FlutterLocalNotificationsPlatform.instance,
    // которого в юнит-тесте нет (плагин не регистрируется). Ставим реальную
    // iOS-реализацию — она ходит в замоканный ниже method-канал.
    FlutterLocalNotificationsPlatform.instance =
        IOSFlutterLocalNotificationsPlugin();
    calls = [];
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notifChannel, (call) async {
      calls.add(call);
      if (call.method == 'pendingNotificationRequests') {
        return <Map<Object?, Object?>>[];
      }
      if (call.method == 'getNotificationAppLaunchDetails') return null;
      return true;
    });
    messenger.setMockMethodCallHandler(tzChannel, (call) async {
      if (call.method == 'getLocalTimezone') return 'UTC';
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notifChannel, null);
    messenger.setMockMethodCallHandler(tzChannel, null);
  });

  Future<NotificationService> makeService({
    required bool enabled,
    required bool dayEmpty,
  }) async {
    final settings = await SettingsStorage.create();
    await settings.setNotificationsEnabled(enabled);
    await settings.setMorningHour(8);
    await settings.setEveningHour(21);
    final service = NotificationService(settings);
    service.bindActivityCheck(() => dayEmpty);
    await service.init();
    calls.clear(); // интересует только rescheduleAll
    return service;
  }

  test('включённые напоминания планируют утро (1001) и вечер (1002)', () async {
    final service = await makeService(enabled: true, dayEmpty: false);
    await service.rescheduleAll();
    expect(scheduledIds(), containsAll(<int>[1001, 1002]));
  });

  test('выключенные — только снимают расписание, ничего не планируют', () async {
    final service = await makeService(enabled: false, dayEmpty: true);
    await service.rescheduleAll();
    expect(scheduledIds(), isEmpty);
    expect(canceledIds(), containsAll(<int>[1001, 1002, 1003]));
  });

  test('тихое напоминание (1003) появляется только когда день пуст', () async {
    final empty = await makeService(enabled: true, dayEmpty: true);
    await empty.rescheduleAll();
    expect(scheduledIds(), contains(1003),
        reason: 'пустой день — тихое напоминание нужно');

    final full = await makeService(enabled: true, dayEmpty: false);
    await full.rescheduleAll();
    expect(scheduledIds().contains(1003), isFalse,
        reason: 'день не пуст — упрекать нечем');
  });
}
