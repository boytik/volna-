import 'package:flutter/material.dart';

/// Палитра «Волны» — система «Печатная страница».
///
/// Материал — бумага, а не стекло: поверхности это оттенки бумаги,
/// границы это волосяные линейки, теней нет. Терракота — единственный
/// акцент. См. DESIGN.md.
///
/// Контраст проверен по WCAG 2.1 на фоне [paper]:
///   inkBody  13.2:1 · inkSoft 5.6:1 · inkQuiet 4.7:1 · accentPress 5.0:1
/// [accent] как текст даёт лишь 3.0:1 — поэтому акцентный **текст**
/// набирается [accentPress], а [accent] остаётся для заливок и линий.
class AppColors {
  AppColors._();

  // ─── Бумага ───────────────────────────────────────────────
  /// Фон всех экранов.
  static const paper = Color(0xFFFAF6F1);

  /// «Вклейка» — приподнятый листок. Заменяет Colors.white:
  /// чистый белый на кремовом читается как дырка.
  static const paperLift = Color(0xFFFFFDFA);

  /// Утопленные зоны: дневник, длинные тексты.
  static const paperSunk = Color(0xFFF1E9DD);

  /// Волосяные линейки. Заменяют все рамки и тени.
  static const rule = Color(0xFFE4D8C6);

  // ─── Чернила ──────────────────────────────────────────────
  /// Крупная антиква. Темнее [inkBody]: большой кегль требует веса.
  static const ink = Color(0xFF241F1B);

  /// Основной текст.
  static const inkBody = Color(0xFF2E2A26);

  /// Вторичный текст.
  static const inkSoft = Color(0xFF6B6259);

  /// Метки, микро-подписи. Затемнён с прежнего #9A9189 (давал 2.9:1
  /// и не проходил AA на 11px).
  static const inkQuiet = Color(0xFF776D63);

  // ─── Вторая краска ────────────────────────────────────────
  /// Единственный акцент. Заливки, линии, иконки — но не текст.
  static const accent = Color(0xFFC97B5C);

  /// Нажатие и акцентный **текст**. Также ColorScheme.error:
  /// в эмоциональном контуре ошибок не существует, красный нужен
  /// только для технических сбоев.
  static const accentPress = Color(0xFFA4553C);

  // ─── Тихие состояния ──────────────────────────────────────
  /// «Отмечено», а не «молодец». Семантики success в системе нет.
  static const marked = Color(0xFF7D9171);
  static const markedWash = Color(0xFFA8B89E);

  // ─── Время суток ──────────────────────────────────────────
  /// Утро — это освещение бумаги, а не цвет кнопки.
  static const dawn = Color(0xFFE8B85C);
  static const dawnWash = Color(0x14E8B85C); // 8%
  static const duskWash = Color(0x0FC97B5C); // 6%

  // ─── SOS ──────────────────────────────────────────────────
  /// Полоса «Мне сейчас плохо». Плоская, вровень с краем экрана.
  static const sos = Color(0xFFE89B8C);

  /// Текст на [sos]. Затемнён с прежнего #7A3A2E (давал 3.8:1).
  static const sosInk = Color(0xFF6B2C1E);

  // ─── Ночная бумага ────────────────────────────────────────
  /// Тёплая, не сине-серая. Никакого slate.
  static const night = Color(0xFF1C1A18);
  static const nightLift = Color(0xFF262320);
  static const nightSunk = Color(0xFF151312);
  static const nightRule = Color(0xFF3A342E);
  static const nightInk = Color(0xFFEFE7DC);
  static const nightInkBody = Color(0xFFE4DACD);
  static const nightInkSoft = Color(0xFFA89C8E);
  static const nightInkQuiet = Color(0xFF8A8073);
  static const nightAccent = Color(0xFFE09A78);

  // ─── Персик ───────────────────────────────────────────────
  /// Единственный остаток прежней палитры.
  ///
  /// Был главным источником «сладости», и с ролей **заливки** снят: ни
  /// фонов блоков, ни подложек под иконками. Остался как цвет значка —
  /// бейджа, техники, темы в библиотеке, — то есть на площади, которую
  /// DESIGN.md ограничивает 10% ширины экрана.
  ///
  /// Заливки, которые тут были, ушли в [paperSunk]. `peachSoft` удалён
  /// вовсе: у него не было ролей, кроме заливочных.
  static const peach = Color(0xFFF5C9A6);
}
