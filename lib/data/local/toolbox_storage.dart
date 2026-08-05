import 'package:shared_preferences/shared_preferences.dart';

/// Личный «toolbox»: что мне помогло.
/// Записывается, когда пользователь после SOS-техники нажал «помогло».
/// На главной можно показать «попробовать что помогло раньше».
///
/// Хранение: счётчик использований по ключу техники + last-used timestamp.

enum ToolKey { breathing, grounding, selfCompassion }

extension ToolKeyExt on ToolKey {
  String get id {
    switch (this) {
      case ToolKey.breathing:
        return 'breathing';
      case ToolKey.grounding:
        return 'grounding';
      case ToolKey.selfCompassion:
        return 'self_compassion';
    }
  }

  String get title {
    switch (this) {
      case ToolKey.breathing:
        return 'Дыхание «Квадрат»';
      case ToolKey.grounding:
        return 'Заземление 5-4-3-2-1';
      case ToolKey.selfCompassion:
        return 'Ладонь на сердце';
    }
  }

  String get route {
    switch (this) {
      case ToolKey.breathing:
        return '/sos/breathing';
      case ToolKey.grounding:
        return '/sos/grounding';
      case ToolKey.selfCompassion:
        return '/sos/self-compassion';
    }
  }
}

class ToolBoxStorage {
  ToolBoxStorage(this._prefs);
  final SharedPreferences _prefs;

  static Future<ToolBoxStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ToolBoxStorage(prefs);
  }

  String _countKey(ToolKey k) => 'tool_count_${k.id}';
  String _lastKey(ToolKey k) => 'tool_last_${k.id}';

  int countOf(ToolKey k) => _prefs.getInt(_countKey(k)) ?? 0;
  DateTime? lastOf(ToolKey k) {
    final s = _prefs.getString(_lastKey(k));
    return s == null ? null : DateTime.tryParse(s);
  }

  Future<void> markHelpful(ToolKey k) async {
    await _prefs.setInt(_countKey(k), countOf(k) + 1);
    await _prefs.setString(_lastKey(k), DateTime.now().toIso8601String());
  }

  /// Самая часто помогавшая техника (для подсказки на главной).
  /// Возвращает null если ни одна не отмечена.
  ToolKey? topTool() {
    ToolKey? best;
    var bestCount = 0;
    for (final k in ToolKey.values) {
      final c = countOf(k);
      if (c > bestCount) {
        bestCount = c;
        best = k;
      }
    }
    return best;
  }

  bool get hasAny =>
      ToolKey.values.any((k) => countOf(k) > 0);

  // Флаги для значков — открыли спец-экран, прошли опросник.
  bool get helpScreenOpened => _prefs.getBool('flag_help_opened') ?? false;
  Future<void> markHelpScreenOpened() =>
      _prefs.setBool('flag_help_opened', true);

  bool get questionnaireCompleted =>
      _prefs.getBool('flag_questionnaire_completed') ?? false;
  Future<void> markQuestionnaireCompleted() =>
      _prefs.setBool('flag_questionnaire_completed', true);
}
