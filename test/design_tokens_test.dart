import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Правила DESIGN.md, которые до сих пор сторожил только чеклист в
/// CLAUDE.md — то есть человек, который про него вспомнил.
///
/// Чеклист заодно смотрел не туда: он проверял `lib/features/`, и
/// поэтому не видел `lib/main.dart`, где экран падения жил с пятью
/// цветами, вписанными числом, и системным шрифтом. Здесь проверяется
/// весь `lib/`, кроме самих токенов.
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  /// Токенам можно всё: они и есть источник значений.
  bool isTheme(File f) => f.path.contains('lib/core/theme/');

  List<String> hitLines(RegExp re, {bool skipTheme = true}) {
    final hits = <String>[];
    for (final f in dartFiles) {
      if (skipTheme && isTheme(f)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (re.hasMatch(lines[i])) {
          hits.add('${f.path}:${i + 1}  ${lines[i].trim()}');
        }
      }
    }
    return hits;
  }

  test('цвета берутся из AppColors, а не вписываются числом', () {
    final hits = hitLines(RegExp(r'Color\(0x'));
    expect(hits, isEmpty, reason: '\n${hits.join('\n')}');
  });

  test('чистого белого нет — есть paperLift', () {
    final hits = hitLines(RegExp(r'Colors\.white'));
    expect(hits, isEmpty, reason: '\n${hits.join('\n')}');
  });

  test('градиентов и теней нет вовсе', () {
    final hits = hitLines(RegExp('Gradient|BoxShadow'), skipTheme: false);
    expect(hits, isEmpty, reason: '\n${hits.join('\n')}');
  });

  test('радиусы только из AppRadius', () {
    // circular(4) — число; circular(AppRadius.sm) — токен.
    final hits = hitLines(RegExp(r'circular\(\s*[0-9]'));
    expect(hits, isEmpty, reason: '\n${hits.join('\n')}');
  });

  test('эмодзи не используются', () {
    // Единственное исключение, и оно временное. Квест «Фоторобот
    // настроения» построен на выборе цвета и набран цветными кружками:
    // заменить их словами — значит переписать упражнение, а контент
    // утверждает психолог. Вопрос задан в docs/questions_for_client.md;
    // как только придёт ответ, строка отсюда уходит.
    const contentPendingAuthor = 'lib/data/content/quests.dart';

    // Диапазоны: пиктограммы, символы и стрелки, дингбаты.
    final hits = hitLines(
      RegExp(
        '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]',
        unicode: true,
      ),
      skipTheme: false,
    ).where((h) => !h.startsWith(contentPendingAuthor)).toList();

    expect(
      hits,
      isEmpty,
      reason: 'DESIGN.md держит эмодзи в списке «Запрещено»\n'
          '${hits.join('\n')}',
    );
  });

  test('персик не используется как заливка', () {
    // DESIGN.md разрешает персик на ≤10% ширины экрана: цвет значка —
    // да, фон блока — нет. Именно через `withValues` он и растекался
    // по блокам и подложкам под иконками.
    final hits = hitLines(RegExp(r'AppColors\.peach\.withValues'));
    expect(hits, isEmpty, reason: '\n${hits.join('\n')}');
  });

  test('accent не набирается текстом — для текста только accentPress', () {
    // 3.0:1 против 5.0:1. Ловим ту форму, которой акцент и попадал в
    // текст: `...textTheme.bodySmall?.copyWith(color: AppColors.accent`.
    final re = RegExp(
      r'\?\.copyWith\(\s*\n\s*color: AppColors\.(accent|terracotta),',
    );
    final bad = <String>[];
    for (final f in dartFiles) {
      if (isTheme(f)) continue;
      if (re.hasMatch(f.readAsStringSync())) bad.add(f.path);
    }
    expect(
      bad,
      isEmpty,
      reason: 'DESIGN.md: accent как текст даёт 3.0:1 и запрещён\n'
          '${bad.join('\n')}',
    );
  });
}
