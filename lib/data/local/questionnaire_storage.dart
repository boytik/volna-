import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../content/questionnaires.dart';

/// История прохождения опросников.
///
/// Экран результата обещает «через 2 недели можно пройти снова — и сравнить»,
/// но сравнивать было не с чем: сохранялся только флаг «опросник пройден».
/// Хранение — как у дневника: JSON-список в одном ключе, объём копеечный
/// (опросник проходят раз в пару недель).
class QuestionnaireRecord {
  const QuestionnaireRecord({
    required this.kind,
    required this.score,
    required this.maxScore,
    required this.zone,
    required this.takenAt,
  });

  final QuestionnaireKind kind;
  final int score;
  final int maxScore;
  final ResultZone zone;
  final DateTime takenAt;

  double get percent => maxScore == 0 ? 0 : score / maxScore;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'score': score,
        'maxScore': maxScore,
        'zone': zone.name,
        'takenAt': takenAt.toIso8601String(),
      };

  static QuestionnaireRecord? fromJson(Map<String, dynamic> j) {
    final kind = QuestionnaireKind.values
        .where((k) => k.name == j['kind'])
        .firstOrNull;
    final zone =
        ResultZone.values.where((z) => z.name == j['zone']).firstOrNull;
    final takenAt = DateTime.tryParse(j['takenAt'] as String? ?? '');
    if (kind == null || zone == null || takenAt == null) return null;

    return QuestionnaireRecord(
      kind: kind,
      score: j['score'] as int? ?? 0,
      maxScore: j['maxScore'] as int? ?? 0,
      zone: zone,
      takenAt: takenAt,
    );
  }
}

class QuestionnaireStorage {
  QuestionnaireStorage(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'questionnaire_history';

  static Future<QuestionnaireStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return QuestionnaireStorage(prefs);
  }

  /// Все прохождения, свежие первыми.
  List<QuestionnaireRecord> all() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      return list
          .map((e) => QuestionnaireRecord.fromJson(e as Map<String, dynamic>))
          .whereType<QuestionnaireRecord>()
          .toList()
        ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    } catch (_) {
      return [];
    }
  }

  List<QuestionnaireRecord> ofKind(QuestionnaireKind kind) =>
      all().where((r) => r.kind == kind).toList();

  /// Предыдущее прохождение этого же опросника (для сравнения на экране
  /// результата). null — если человек проходит его впервые.
  QuestionnaireRecord? previousOf(QuestionnaireKind kind) {
    final history = ofKind(kind);
    return history.length < 2 ? null : history[1];
  }

  QuestionnaireRecord? lastOf(QuestionnaireKind kind) =>
      ofKind(kind).firstOrNull;

  Future<void> add(QuestionnaireResult result, {DateTime? takenAt}) async {
    final records = all()
      ..insert(
        0,
        QuestionnaireRecord(
          kind: result.kind,
          score: result.score,
          maxScore: result.maxScore,
          zone: result.zone,
          takenAt: takenAt ?? DateTime.now(),
        ),
      );
    await _prefs.setString(
      _key,
      json.encode(records.map((r) => r.toJson()).toList()),
    );
  }
}
