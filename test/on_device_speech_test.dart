import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volna/services/on_device_transcribe_service.dart';

/// Сторожит контракт локального распознавания.
///
/// Само распознавание проверить в тестах нельзя — оно живёт в системе
/// и требует живого телефона со скачанным пакетом диктовки. Зато можно
/// проверить то, от чего зависит текст про приватность: как сервис
/// отвечает, когда платформа недоступна или отвечает «не умею».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('io.volna.volna/speech');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // Обработчик может быть null — это и есть случай «канала нет».
  void mock(Future<Object?>? Function(MethodCall)? handler) {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  tearDown(() => mock(null));

  group('Доступность локального распознавания', () {
    test('канала нет — считаем, что телефон не умеет', () async {
      mock(null);
      final service = OnDeviceTranscribeService();
      expect(await service.supportsOnDevice(), isFalse);
    });

    test('платформа сказала «нет» — значит нет', () async {
      mock((_) async => false);
      expect(await OnDeviceTranscribeService().supportsOnDevice(), isFalse);
    });

    test('платформа сказала «да» — значит да', () async {
      mock((_) async => true);
      expect(await OnDeviceTranscribeService().supportsOnDevice(), isTrue);
    });

    test('ошибка платформы не роняет экран, а читается как «не умеет»',
        () async {
      mock((_) async => throw PlatformException(code: 'boom'));
      expect(await OnDeviceTranscribeService().supportsOnDevice(), isFalse);
    });

    test('спрашиваем русскую локаль', () async {
      String? asked;
      mock((call) async {
        asked = (call.arguments as Map)['locale'] as String?;
        return true;
      });
      await OnDeviceTranscribeService().supportsOnDevice();
      expect(asked, 'ru-RU');
    });

    test('ответ спрашивается один раз за сессию', () async {
      var calls = 0;
      mock((_) async {
        calls++;
        return true;
      });
      final service = OnDeviceTranscribeService();
      await service.supportsOnDevice();
      await service.supportsOnDevice();
      await service.supportsOnDevice();
      expect(
        calls,
        1,
        reason: 'пакет диктовки не появится в середине разговора',
      );
    });
  });

  group('Ограничения записи', () {
    test('потолок тот же, что был у облачной записи', () {
      expect(OnDeviceTranscribeService.maxDuration.inSeconds, 90);
    });

    test('локаль русская', () {
      expect(OnDeviceTranscribeService.localeId, 'ru-RU');
    });
  });
}
