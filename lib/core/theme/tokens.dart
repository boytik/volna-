import 'package:flutter/material.dart';

/// Токены «Печатной страницы».
///
/// Замкнутые наборы: если нужного значения здесь нет — это не значит
/// «впиши число на месте», это значит «обсуди добавление в систему».
/// До введения токенов по `lib/features/` было 11 разных радиусов
/// скруглений и 85 вызовов `withValues`, изобретавших оттенки в месте
/// использования. См. DESIGN.md.

/// Шаг сетки — 4px.
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const smd = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
  static const huge = 96.0;

  /// Левая ось набора. Едина для всех экранов.
  static const axis = 24.0;

  /// Правое поле. Больше левого — асимметрия и есть подпись направления.
  static const marginRight = 56.0;

  /// Воздух над первой строкой экрана.
  static const skyline = 88.0;
}

/// Три радиуса вместо одиннадцати.
class AppRadius {
  AppRadius._();

  /// Полосы вровень с краем экрана (SOS).
  static const none = 0.0;

  /// Вклейки и кнопки. Переход с 16–24 на 4 — это и есть визуальный
  /// сдвиг от «приложение» к «печать».
  static const sm = 4.0;

  /// Медиа и крупные плоскости.
  static const md = 12.0;

  static const smR = BorderRadius.all(Radius.circular(sm));
  static const mdR = BorderRadius.all(Radius.circular(md));
}

/// Движение. Только длинные ease-out, ни одной пружины:
/// springs читаются как нетерпение.
class AppMotion {
  AppMotion._();

  static const tap = Duration(milliseconds: 180);
  static const state = Duration(milliseconds: 700);
  static const slow = Duration(milliseconds: 900);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;

  /// Бесконечных анимаций в системе нет. Перед любой анимацией
  /// состояния спрашивай это — при включённом «уменьшении движения»
  /// переход должен быть мгновенным, а не ускоренным.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration stateFor(BuildContext context) =>
      reduced(context) ? Duration.zero : state;
}

/// Толщина волосяной линейки. Линейки заменяют рамки и тени —
/// теней в системе нет вовсе.
class AppStroke {
  AppStroke._();

  static const hairline = 1.0;
}
