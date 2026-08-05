import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Дневник: 3 формы.
/// Хранение — JSON-список в одном ключе `diary_entries`.
/// Объём ожидаем небольшой (1-2 записи в день), для MVP этого достаточно.

enum DiaryKind {
  /// Три хороших события (вечерний, позитивная психология).
  threeGood,
  /// Конверт для тревоги (запись + срок переоткрытия).
  envelope,
  /// «Подруга на твоём месте» (CBT-перестройка вины).
  friendOnYourPlace,
}

extension DiaryKindExt on DiaryKind {
  String get label {
    switch (this) {
      case DiaryKind.threeGood:
        return 'Три хороших события';
      case DiaryKind.envelope:
        return 'Конверт для тревоги';
      case DiaryKind.friendOnYourPlace:
        return 'Подруга на твоём месте';
    }
  }
}

class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.payload,
    this.envelopeStatus,
    this.envelopeReopenAt,
    this.envelopeNotificationId,
  });

  final String id;
  final DiaryKind kind;
  final DateTime createdAt;
  /// Содержимое — структура зависит от kind:
  /// — threeGood: {'one': ..., 'two': ..., 'three': ...}
  /// — envelope: {'thought': ...}
  /// — friendOnYourPlace: {'guilt': ..., 'kind_response': ...}
  final Map<String, String> payload;

  /// Статус конверта: 'sealed' (закрыт), 'discarded' (выброшен), 'reopened' (переоткрыт).
  String? envelopeStatus;
  DateTime? envelopeReopenAt;
  int? envelopeNotificationId;

  /// Копия с изменёнными полями конверта.
  /// Пересобирать запись вручную нельзя — легко потерять поле
  /// (так уже терялся `envelopeNotificationId`, и выброшенный конверт
  /// возвращался пушем через сутки).
  DiaryEntry copyWith({
    String? envelopeStatus,
    DateTime? envelopeReopenAt,
    int? envelopeNotificationId,
    bool clearNotificationId = false,
  }) =>
      DiaryEntry(
        id: id,
        kind: kind,
        createdAt: createdAt,
        payload: payload,
        envelopeStatus: envelopeStatus ?? this.envelopeStatus,
        envelopeReopenAt: envelopeReopenAt ?? this.envelopeReopenAt,
        envelopeNotificationId: clearNotificationId
            ? null
            : (envelopeNotificationId ?? this.envelopeNotificationId),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.index,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        'envelopeStatus': envelopeStatus,
        'envelopeReopenAt': envelopeReopenAt?.toIso8601String(),
        'envelopeNotificationId': envelopeNotificationId,
      };

  static DiaryEntry fromJson(Map<String, dynamic> j) => DiaryEntry(
        id: j['id'] as String,
        kind: DiaryKind.values[j['kind'] as int],
        createdAt: DateTime.parse(j['createdAt'] as String),
        payload: Map<String, String>.from(j['payload'] as Map),
        envelopeStatus: j['envelopeStatus'] as String?,
        envelopeReopenAt: j['envelopeReopenAt'] == null
            ? null
            : DateTime.parse(j['envelopeReopenAt'] as String),
        envelopeNotificationId: j['envelopeNotificationId'] as int?,
      );
}

class DiaryStorage {
  DiaryStorage(this._prefs);
  final SharedPreferences _prefs;

  static Future<DiaryStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DiaryStorage(prefs);
  }

  static const _key = 'diary_entries';

  List<DiaryEntry> all() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<DiaryEntry> ofKind(DiaryKind k) =>
      all().where((e) => e.kind == k).toList();

  Future<void> add(DiaryEntry e) async {
    final entries = all();
    entries.add(e);
    await _save(entries);
  }

  Future<void> update(DiaryEntry e) async {
    final entries = all();
    final idx = entries.indexWhere((x) => x.id == e.id);
    if (idx == -1) return;
    entries[idx] = e;
    await _save(entries);
  }

  Future<void> remove(String id) async {
    final entries = all();
    entries.removeWhere((e) => e.id == id);
    await _save(entries);
  }

  Future<void> _save(List<DiaryEntry> entries) async {
    final raw = json.encode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  /// Конверты, у которых наступило время переоткрытия (для кнопки в шапке экрана).
  List<DiaryEntry> get envelopesReadyToReopen {
    final now = DateTime.now();
    return ofKind(DiaryKind.envelope).where((e) {
      if (e.envelopeStatus != 'sealed') return false;
      final at = e.envelopeReopenAt;
      if (at == null) return false;
      return at.isBefore(now);
    }).toList();
  }
}
