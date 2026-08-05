import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'data/content/quests.dart';
import 'data/local/badges_storage.dart';
import 'data/local/checkin_storage.dart';
import 'data/local/diary_storage.dart';
import 'data/local/quest_storage.dart';
import 'data/local/questionnaire_storage.dart';
import 'data/local/settings_storage.dart';
import 'data/local/toolbox_storage.dart';
import 'services/badges_service.dart';
import 'services/notification_service.dart';

late final QuestStorage questStorage;
late final SettingsStorage settingsStorage;
late final CheckInStorage checkInStorage;
late final DiaryStorage diaryStorage;
late final ToolBoxStorage toolBoxStorage;
late final BadgesStorage badgesStorage;
late final QuestionnaireStorage questionnaireStorage;
late final NotificationService notificationService;
late final BadgesService badgesService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    questStorage = await QuestStorage.create();
    // Кольца у основания древа считаются от первого запуска, поэтому
    // дату нужно поставить до первой отрисовки.
    await questStorage.ensureFirstSeen();
    settingsStorage = await SettingsStorage.create();
    checkInStorage = await CheckInStorage.create();
    diaryStorage = await DiaryStorage.create();
    toolBoxStorage = await ToolBoxStorage.create();
    badgesStorage = await BadgesStorage.create();
    questionnaireStorage = await QuestionnaireStorage.create();
    notificationService = NotificationService(settingsStorage);
    notificationService.bindActivityCheck(
      () => !questStorage.isDoneToday(QuestSlot.morning) &&
          !questStorage.isDoneToday(QuestSlot.evening),
    );
    badgesService = BadgesService(
      badgesStorage: badgesStorage,
      questStorage: questStorage,
      checkInStorage: checkInStorage,
      diaryStorage: diaryStorage,
      toolBoxStorage: toolBoxStorage,
    );

    // Уведомления опциональны — если плагин ломается (особенно на вебе),
    // ловим, но не блокируем запуск приложения.
    try {
      await notificationService.init();
      await notificationService.rescheduleAll();
    } catch (e, st) {
      debugPrint('Notifications init skipped: $e\n$st');
    }

    runApp(const VolnaApp());
  } catch (e, st) {
    debugPrint('Fatal init error: $e\n$st');
    runApp(_FatalErrorApp(message: '$e'));
  }
}

class VolnaApp extends StatelessWidget {
  const VolnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Волна',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Ночная бумага следует системной теме. По часам устройства
      // было бы неожиданно: приложение темнеет, когда система светлая.
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}

/// Показывается, если main-инициализация полностью упала.
/// Никаких сложных зависимостей.
class _FatalErrorApp extends StatelessWidget {
  const _FatalErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Волна',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFAF6F1),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Color(0xFFC97B5C),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Не получилось запустить',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2A26),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Попробуй обновить страницу. Если не помогает — '
                  'напиши нам, что случилось.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B6259),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A9189),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
