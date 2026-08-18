import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volna/core/theme/app_theme.dart';
import 'package:volna/core/widgets/leaves_device_mark.dart';
import 'package:volna/features/vent/vent_choice_screen.dart';

/// Знак «уходит на сервер» показывается ровно тогда, когда на **этом**
/// телефоне аудио действительно уходит.
///
/// Раньше это сторожил grep по `leavesDevice: true` в
/// navigation_test.dart. Он ловил одну-единственную форму записи:
/// безусловный `const LeavesDeviceMark()` или
/// `leavesDevice: чтоУгодноВсегдаИстинное` прошли бы мимо. Здесь
/// отвечает сам экран — подставляем ответ платформы и смотрим, что
/// нарисовалось.
///
/// Безусловный знак был бы таким же враньём, как его отсутствие: он
/// перестал бы что-либо значить.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('io.volna.volna/speech');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// `null` — обработчика нет, и ответ не приходит вовсе: так выглядит
  /// платформа, которая ещё не ответила.
  void answerPlatform(bool? supportsOnDevice) {
    messenger.setMockMethodCallHandler(
      channel,
      supportsOnDevice == null ? null : (_) async => supportsOnDevice,
    );
  }

  tearDown(() => answerPlatform(null));

  Future<void> pumpChoice(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const VentChoiceScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('телефон распознаёт сам — знака нет', (tester) async {
    answerPlatform(true);
    await pumpChoice(tester);

    expect(
      find.byType(LeavesDeviceMark),
      findsNothing,
      reason: 'запись не покидает устройство — пугать нечем',
    );
  });

  testWidgets('телефон не умеет — знак стоит', (tester) async {
    answerPlatform(false);
    await pumpChoice(tester);

    expect(
      find.byType(LeavesDeviceMark),
      findsOneWidget,
      reason: 'аудио уйдёт на расшифровку, и это должно быть видно',
    );
  });

  testWidgets('платформа ещё не ответила — ни знака, ни обещаний',
      (tester) async {
    answerPlatform(null);
    await pumpChoice(tester);

    expect(
      find.byType(LeavesDeviceMark),
      findsNothing,
      reason: 'пугать до того, как узнали, нечестно',
    );
    expect(
      find.textContaining('запись никуда не уходит'),
      findsNothing,
      reason: 'и обещать до того, как узнали, тоже нельзя',
    );
    expect(
      find.textContaining('запись уйдёт на расшифровку'),
      findsNothing,
    );
  });

  testWidgets('знак ровно один и только у голоса', (tester) async {
    // Текстовый способ никуда ничего не отправляет. Если знак когда-нибудь
    // расползётся на всю страницу, их станет два.
    answerPlatform(false);
    await pumpChoice(tester);

    expect(find.byType(LeavesDeviceMark), findsOneWidget);
    expect(find.text('Голосом'), findsOneWidget);
    expect(find.text('Текстом'), findsOneWidget);
  });
}
