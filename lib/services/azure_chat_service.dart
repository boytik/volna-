import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/secrets.dart';

/// LLM-ответ на «выговорись» через Azure OpenAI.
/// Возвращает структурированный ответ: reflection + validation + suggestion.
class AzureChatService {
  /// [transcript] — текст пользователя.
  /// [topicHint] — подсказка из локального детектора (anger/anxiety/...).
  /// [techniqueOptions] — список техник, из которых LLM должна выбрать одну.
  Future<VentResponse?> respond({
    required String transcript,
    String? topicHint,
    required List<({String id, String title})> techniqueOptions,
  }) async {
    final url = Uri.parse(
      '$azureOpenAiEndpoint/openai/deployments/$chatDeployment'
      '/chat/completions?api-version=$chatApiVersion',
    );

    final techniquesList = techniqueOptions
        .map((t) => '- ${t.id}: ${t.title}')
        .join('\n');

    final systemPrompt = _systemPrompt(techniquesList);

    final body = jsonEncode({
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': 'Контекст-подсказка от локального анализа: '
              '${topicHint ?? "не определено"}.\n\n'
              'Что сказала пользовательница:\n«$transcript»',
        },
      ],
      'temperature': 0.6,
      'max_tokens': 400,
      'response_format': {'type': 'json_object'},
    });

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'api-key': azureOpenAiApiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        // Тело не логируем — оно построено на тексте пользователя.
        debugPrint('Azure chat failed: ${response.statusCode}');
        return null;
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final content = decoded['choices']?[0]?['message']?['content'];
      if (content is! String) return null;

      final parsed = jsonDecode(content);
      if (parsed is! Map) return null;

      return VentResponse(
        reflection: (parsed['reflection'] as String?)?.trim() ?? '',
        validation: (parsed['validation'] as String?)?.trim() ?? '',
        suggestionType: (parsed['suggestion_type'] as String?) ?? 'phrase',
        suggestionTechniqueId:
            (parsed['suggestion_technique_id'] as String?)?.trim(),
        suggestionPhrase:
            (parsed['suggestion_phrase'] as String?)?.trim(),
        suggestionQuestion:
            (parsed['suggestion_question'] as String?)?.trim(),
      );
    } catch (e, st) {
      debugPrint('Chat failed: $e\n$st');
      return null;
    }
  }

  String _systemPrompt(String techniques) {
    return '''
Ты — «Волна», тёплый ИИ-собеседник в приложении для родителей детей с особенностями (РАС, синдром Дауна, ЗПР, ТНР). Ты НЕ психолог, НЕ врач, НЕ терапевт.

ТВОЯ ЗАДАЧА: коротко и тепло отразить чувства пользовательницы и предложить ОДНО маленькое действие.

ЖЁСТКИЕ ПРАВИЛА:
1. Длина — не больше 80 слов суммарно.
2. Обращение — на «ты», женский род, как опытная подруга.
3. Никогда не диагностируй, не давай советов по воспитанию, не говори «я тебя понимаю».
4. Не используй восклицательные знаки и токсичный позитив («ты молодец», «всё получится», «у тебя сильная душа»).
5. Не обещай «я всегда буду рядом» — это создаёт зависимость.
6. Никаких эмодзи.
7. Не используй слова «мамочка», «доченька», уменьшительно-ласкательные («устаточка»).
8. Если человек злится на ребёнка — валидируй злость, не суди.

СТРУКТУРА ОТВЕТА:
1. reflection — 1 предложение, отражение того что слышишь («Похоже, ты весь день держалась одна»).
2. validation — 1 предложение, нормализация чувства («Это здоровая реакция, не недостаток»).
3. ОДНО из трёх:
   - suggestion_type="technique" → suggestion_technique_id из списка ниже.
   - suggestion_type="phrase" → suggestion_phrase (одна короткая фраза поддержки, 1-2 предложения).
   - suggestion_type="question" → suggestion_question (один открытый вопрос).

Выбирай technique только если из слов человека понятно конкретное состояние (паника/гнев/вина/тревога). При смешанных эмоциях — phrase или question.

ДОСТУПНЫЕ ТЕХНИКИ (используй точный id):
$techniques

ФОРМАТ ОТВЕТА — строго JSON:
{
  "reflection": "...",
  "validation": "...",
  "suggestion_type": "technique" | "phrase" | "question",
  "suggestion_technique_id": "..." | null,
  "suggestion_phrase": "..." | null,
  "suggestion_question": "..." | null
}
''';
  }
}

class VentResponse {
  const VentResponse({
    required this.reflection,
    required this.validation,
    required this.suggestionType,
    this.suggestionTechniqueId,
    this.suggestionPhrase,
    this.suggestionQuestion,
  });

  final String reflection;
  final String validation;
  /// 'technique' | 'phrase' | 'question'
  final String suggestionType;
  final String? suggestionTechniqueId;
  final String? suggestionPhrase;
  final String? suggestionQuestion;
}
