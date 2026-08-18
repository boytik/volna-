import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'core/theme/tokens.dart';
import 'core/theme/typography.dart';
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
///
/// Зависимостей по-прежнему минимум: `AppColors` — константы, а
/// `AppTypography` — чистая функция над вшитыми в assets шрифтами.
/// Ничего из этого не требует инициализации, которая только что не
/// удалась.
///
/// Раньше экран был набран пятью цветами, вписанными числом, и
/// системным шрифтом: чеклист из CLAUDE.md смотрит в `lib/features/`
/// и сюда не заглядывал. Среди них жил `0xFF9A9189` — снятое значение
/// `inkQuiet`, которое затемнили именно потому, что оно давало 2.9:1
/// и не проходило AA, да ещё на кегле 12.
class _FatalErrorApp extends StatelessWidget {
  const _FatalErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Волна',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Не получилось запустить',
                  style: AppTypography.voice(size: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.smd),
                Text(
                  'Попробуй закрыть приложение и открыть заново. '
                  'Если не помогает — напиши нам, что случилось.',
                  style: TextStyle(
                    fontFamily: AppTypography.sansFamily,
                    fontSize: 15,
                    height: 23 / 15,
                    color: AppColors.inkSoft,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: AppTypography.sansFamily,
                      fontSize: 13,
                      color: AppColors.inkQuiet,
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
