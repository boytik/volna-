// Живая проверка облачного контура «выговорись».
//
// ignore_for_file: avoid_print — печать здесь и есть результат: файл
// запускают руками, чтобы глазами прочитать, что ответил Azure.
//
// Не заканчивается на `_test.dart` намеренно: `flutter test` без
// аргументов её не подхватит. Она ходит в настоящий Azure и требует
// реального ключа в lib/config/secrets.dart, так что в CI ей делать
// нечего. Запуск руками:
//
//   flutter test test/azure_live_probe.dart
//
// Проверяет ровно то, чего не проверит curl: как запрос собирает сам
// сервис приложения и как он разбирает ответ.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:volna/config/secrets.dart';
import 'package:volna/data/content/sos_techniques.dart';
import 'package:volna/services/azure_chat_service.dart';
import 'package:volna/services/azure_transcribe_service.dart';

void main() {
  test('AzureChatService отвечает на текст', () async {
    expect(
      azureOpenAiApiKey.isNotEmpty,
      isTrue,
      reason: 'в lib/config/secrets.dart пустой ключ — проверять нечего',
    );

    final options =
        allTechniques.map((t) => (id: t.id, title: t.title)).toList();

    final response = await AzureChatService().respond(
      transcript: 'Я сегодня наорала на сына и весь вечер себя за это ем. '
          'Устала так, что даже плакать не выходит.',
      topicHint: 'guilt',
      techniqueOptions: options,
    );

    expect(response, isNotNull, reason: 'Azure не ответил или ответ не разобрался');

    print('--- отражение ---\n${response!.reflection}');
    print('--- нормализация ---\n${response.validation}');
    print('--- тип подсказки --- ${response.suggestionType}');
    print('техника: ${response.suggestionTechniqueId}');
    print('фраза:   ${response.suggestionPhrase}');
    print('вопрос:  ${response.suggestionQuestion}');

    expect(response.reflection, isNotEmpty);
    expect(response.validation, isNotEmpty);

    // Если модель выбрала технику — она обязана быть из нашего списка,
    // иначе экран ответа не найдёт, что показать.
    if (response.suggestionType == 'technique') {
      expect(
        options.map((o) => o.id),
        contains(response.suggestionTechniqueId),
        reason: 'модель выдумала id техники',
      );
    }
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('AzureTranscribeService разбирает записанный файл', () async {
    expect(azureOpenAiApiKey.isNotEmpty, isTrue);

    // Файл в том же контейнере, в котором пишет AudioRecorderService.
    final f = File('/tmp/t.m4a');
    if (!f.existsSync()) {
      print('нет /tmp/t.m4a — пропускаю');
      return;
    }

    final text = await AzureTranscribeService().transcribe(
      bytes: f.readAsBytesSync(),
      filename: 'audio.m4a',
    );

    print('--- расшифровка ---\n$text');
    expect(text, isNotNull, reason: 'Azure не расшифровал .m4a');
    expect(text!.trim(), isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
