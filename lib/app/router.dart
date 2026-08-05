import 'package:go_router/go_router.dart';

import '../data/content/crisis_keywords.dart';
import '../data/content/quests.dart';
import '../data/content/questionnaires.dart';
import '../data/content/vent_keywords.dart';
import '../data/local/diary_storage.dart';
import '../features/badges/badges_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/diary/diary_list_screen.dart';
import '../features/diary/diary_new_screen.dart';
import '../features/diary/envelope_reopen_screen.dart';
import '../features/help/help_screen.dart';
import '../features/help/prepare_session_screen.dart';
import '../features/home/home_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/library/library_screen.dart';
import '../features/library/phrases_screen.dart';
import '../features/library/resources_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/quest/quest_screen.dart';
import '../features/quest/survival_screen.dart';
import '../features/questionnaire/questionnaire_list_screen.dart';
import '../features/questionnaire/questionnaire_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/sos/breathing_screen.dart';
import '../features/sos/grounding_screen.dart';
import '../features/sos/self_compassion_screen.dart';
import '../features/sos/sos_menu_screen.dart';
import '../features/sos/technique_screen.dart';
import '../features/tree/tree_screen.dart';
import '../features/vent/crisis_screen.dart';
import '../features/vent/vent_response_screen.dart';
import '../features/vent/vent_screen.dart';
import '../features/vent/voice_vent_screen.dart';
import '../main.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isOnboarding = state.matchedLocation == '/onboarding';
    // Экран про данные доступен и до онбординга: согласие даётся осознанно,
    // значит прочитать условия нужно уметь до того, как что-то нажал.
    final isPrivacy = state.matchedLocation == '/privacy';
    if (!settingsStorage.onboardingDone && !isOnboarding && !isPrivacy) {
      return '/onboarding';
    }
    if (settingsStorage.onboardingDone && isOnboarding) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
    GoRoute(path: '/badges', builder: (_, _) => const BadgesScreen()),

    // SOS
    GoRoute(path: '/sos', builder: (_, _) => const SosMenuScreen()),
    GoRoute(path: '/sos/breathing', builder: (_, _) => const BreathingScreen()),
    GoRoute(path: '/sos/grounding', builder: (_, _) => const GroundingScreen()),
    GoRoute(path: '/sos/self-compassion', builder: (_, _) => const SelfCompassionScreen()),
    GoRoute(
      path: '/sos/technique/:id',
      builder: (_, state) =>
          TechniqueScreen(id: state.pathParameters['id']!),
    ),

    // Кризис — детерминированный экран, общий для всех точек ввода текста.
    GoRoute(
      path: '/crisis',
      builder: (_, state) {
        final raw = state.uri.queryParameters['category'];
        final category = CrisisCategory.values.firstWhere(
          (c) => c.name == raw,
          orElse: () => CrisisCategory.suicide,
        );
        return CrisisScreen(category: category);
      },
    ),

    // Vent — голос по умолчанию, текст как fallback
    GoRoute(path: '/vent', builder: (_, _) => const VoiceVentScreen()),
    GoRoute(path: '/vent/text', builder: (_, _) => const VentScreen()),
    GoRoute(
      path: '/vent/response',
      builder: (_, state) {
        final raw = state.uri.queryParameters['topic'] ?? 'general';
        final topic = VentTopic.values.firstWhere(
          (t) => t.name == raw,
          orElse: () => VentTopic.general,
        );
        return VentResponseScreen(topic: topic);
      },
    ),

    // Quests
    GoRoute(
      path: '/quest/morning',
      builder: (_, _) =>
          QuestScreen(slot: QuestSlot.morning, storage: questStorage),
    ),
    GoRoute(
      path: '/quest/evening',
      builder: (_, _) =>
          QuestScreen(slot: QuestSlot.evening, storage: questStorage),
    ),
    GoRoute(
      path: '/survival/morning',
      builder: (_, _) => const SurvivalScreen(slot: QuestSlot.morning),
    ),
    GoRoute(
      path: '/survival/evening',
      builder: (_, _) => const SurvivalScreen(slot: QuestSlot.evening),
    ),

    // Tree, calendar, library
    GoRoute(path: '/tree', builder: (_, _) => const TreeScreen()),
    GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
    GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
    GoRoute(path: '/library', builder: (_, _) => const LibraryScreen()),
    GoRoute(
      path: '/library/phrases/:id',
      builder: (_, state) =>
          PhrasesScreen(categoryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/library/resources',
      builder: (_, _) => const ResourcesScreen(),
    ),

    // Diary
    GoRoute(path: '/diary', builder: (_, _) => const DiaryListScreen()),
    GoRoute(
      path: '/diary/new/three-good',
      builder: (_, _) => const DiaryNewScreen(kind: DiaryKind.threeGood),
    ),
    GoRoute(
      path: '/diary/new/envelope',
      builder: (_, _) => const DiaryNewScreen(kind: DiaryKind.envelope),
    ),
    GoRoute(
      path: '/diary/new/friend',
      builder: (_, _) =>
          const DiaryNewScreen(kind: DiaryKind.friendOnYourPlace),
    ),
    GoRoute(
      path: '/diary/envelope/:id',
      builder: (_, state) =>
          EnvelopeReopenScreen(id: state.pathParameters['id']!),
    ),

    // Help / specialist
    GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
    GoRoute(path: '/help/prepare', builder: (_, _) => const PrepareSessionScreen()),

    // Questionnaires
    GoRoute(path: '/questionnaire', builder: (_, _) => const QuestionnaireListScreen()),
    GoRoute(
      path: '/questionnaire/:kind',
      builder: (_, state) {
        final raw = state.pathParameters['kind']!;
        final kind = QuestionnaireKind.values.firstWhere(
          (k) => k.name == raw,
          orElse: () => QuestionnaireKind.csi,
        );
        return QuestionnaireScreen(kind: kind);
      },
    ),
  ],
);
