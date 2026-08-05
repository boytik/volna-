import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Древо устойчивости — контурный рисунок волосяной линией.
///
/// Ключевое правило системы: **состояния хуже вчерашнего не существует.**
/// Древо нарисовано целиком с первого запуска — его не выращивают,
/// под ним сидят. Раньше здесь был `TreeMood`, который бледнил рисунок
/// при пропуске дня и «усыплял» через неделю: визуальная вина, ровно
/// та механика, от которой продукт отстраивается. Она удалена.
///
/// Меняются только две вещи, и обе — вверх:
///   [rings]  — кольца у основания, по одному за прожитую неделю.
///              Растут от того, что время идёт, а не от дисциплины.
///   [lights] — тёплые следы недавних практик. Гаснут за ~10 дней,
///              и это заявлено текстом: «следы гаснут, дерево остаётся».
enum Season { winter, spring, summer, autumn }

Season seasonForMonth(int month) {
  if (month == 12 || month == 1 || month == 2) return Season.winter;
  if (month >= 3 && month <= 5) return Season.spring;
  if (month >= 6 && month <= 8) return Season.summer;
  return Season.autumn;
}

String seasonLabel(Season s) {
  switch (s) {
    case Season.winter:
      return 'Зима';
    case Season.spring:
      return 'Весна';
    case Season.summer:
      return 'Лето';
    case Season.autumn:
      return 'Осень';
  }
}

class TreePainter extends CustomPainter {
  TreePainter({
    required this.rings,
    required this.lights,
    required this.season,
    required this.inkColor,
    required this.ruleColor,
  });

  /// Прожитые недели. Не может уменьшиться.
  final int rings;

  /// Возраст следов в днях (0 — сегодня). Чем старше, тем тусклее.
  final List<int> lights;

  final Season season;
  final Color inkColor;
  final Color ruleColor;

  static const _lightLifespanDays = 10.0;

  /// Ветви: (угол от вертикали, длина в долях кроны, радиус узла,
  /// точка отхода от ствола в долях его высоты — 0 у земли, 1 у вершины).
  /// Разные точки отхода важны: когда все ветви выходят из одной,
  /// рисунок читается букетом, а не деревом.
  static const _limbs = <(double, double, double, double)>[
    (-0.70, 0.62, 0.115, 0.46),
    (0.64, 0.54, 0.098, 0.62),
    (-0.42, 0.72, 0.082, 0.78),
    (0.34, 0.86, 0.142, 0.90),
    (-0.05, 0.95, 0.120, 1.00),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height * 0.86;
    final trunkTop = Offset(cx, groundY - size.height * 0.56);

    _paintGround(canvas, cx, groundY, size);
    _paintTrunk(canvas, Offset(cx, groundY), trunkTop);

    final nodes = _paintLimbs(canvas, trunkTop, size);
    _paintLights(canvas, nodes);
    _paintRings(canvas, cx, groundY, size);

    if (season == Season.autumn) {
      _paintFallen(canvas, cx, groundY, size);
    }
  }

  Paint _hair(double width) => Paint()
    ..color = inkColor
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = width;

  void _paintGround(Canvas canvas, double cx, double groundY, Size size) {
    final w = size.width * 0.34;
    canvas.drawLine(
      Offset(cx - w / 2, groundY),
      Offset(cx + w / 2, groundY),
      Paint()
        ..color = ruleColor
        ..strokeWidth = 1.0,
    );
  }

  void _paintTrunk(Canvas canvas, Offset base, Offset top) {
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + 3,
        (base.dy + top.dy) / 2,
        top.dx,
        top.dy,
      );
    canvas.drawPath(path, _hair(1.5));
  }

  /// Рисует ветви и обводки крон, возвращает центры узлов с радиусами.
  List<(Offset, double)> _paintLimbs(
    Canvas canvas,
    Offset trunkTop,
    Size size,
  ) {
    final trunkH = size.height * 0.56;
    final trunkBaseY = trunkTop.dy + trunkH;
    final crownH = size.height * 0.34;
    final nodes = <(Offset, double)>[];
    // Зимой крона реже — верхние узлы остаются, нижние облетели.
    final visible = season == Season.winter ? 3 : _limbs.length;
    final skip = _limbs.length - visible;

    for (var i = skip; i < _limbs.length; i++) {
      final (angle, lengthK, radiusK, originK) = _limbs[i];
      // Ветвь отходит от своей точки на стволе, а не от общей вершины.
      final origin = Offset(trunkTop.dx, trunkBaseY - trunkH * originK);
      final len = crownH * lengthK;
      final end = origin.translate(
        math.sin(angle) * len,
        -math.cos(angle) * len * 0.78,
      );
      final ctrl = Offset.lerp(origin, end, 0.5)!.translate(
            math.sin(angle) * 5,
            6,
          );

      final branch = Path()
        ..moveTo(origin.dx, origin.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      canvas.drawPath(branch, _hair(1.2));

      final r = size.width * radiusK;
      canvas.drawCircle(end, r, _hair(1.0));
      nodes.add((end, r));
    }
    return nodes;
  }

  /// Следы практик — тёплые точки в кроне, тускнеющие с возрастом.
  /// Ничего не «отваливается»: точка гаснет до нуля и исчезает.
  void _paintLights(Canvas canvas, List<(Offset, double)> nodes) {
    if (nodes.isEmpty) return;
    final rng = math.Random(17);

    for (var i = 0; i < lights.length; i++) {
      final age = lights[i];
      final fade = (1 - age / _lightLifespanDays).clamp(0.0, 1.0);
      if (fade <= 0) continue;

      final (center, radius) = nodes[i % nodes.length];
      final angle = rng.nextDouble() * math.pi * 2;
      final dist = radius * (0.15 + rng.nextDouble() * 0.55);
      final pos = center.translate(
        math.cos(angle) * dist,
        math.sin(angle) * dist,
      );

      canvas.drawCircle(
        pos,
        2.6,
        Paint()..color = AppColors.dawn.withValues(alpha: 0.25 + 0.75 * fade),
      );
    }
  }

  /// Кольца прожитых недель. Заполненных ровно [rings];
  /// незаработанных заглушек не рисуем — их не существует.
  void _paintRings(Canvas canvas, double cx, double groundY, Size size) {
    if (rings <= 0) return;

    const gap = 9.0;
    const r = 3.2;
    // Больше 12 колец переносим во второй ряд, чтобы не выходить за поле.
    const perRow = 12;
    final rowCount = (rings / perRow).ceil();

    var drawn = 0;
    for (var row = 0; row < rowCount; row++) {
      final inRow = math.min(perRow, rings - drawn);
      final rowWidth = (inRow - 1) * gap;
      final startX = cx - rowWidth / 2;
      final y = groundY + 12 + row * gap;

      for (var i = 0; i < inRow; i++) {
        canvas.drawCircle(
          Offset(startX + i * gap, y),
          r,
          Paint()..color = AppColors.marked,
        );
      }
      drawn += inRow;
    }
  }

  void _paintFallen(Canvas canvas, double cx, double groundY, Size size) {
    final rng = math.Random(11);
    final paint = _hair(1.0);
    for (var i = 0; i < 3; i++) {
      final dx = (rng.nextDouble() - 0.5) * size.width * 0.5;
      final pos = Offset(cx + dx, groundY - 3 - rng.nextDouble() * 4);
      canvas.drawArc(
        Rect.fromCenter(center: pos, width: 9, height: 5),
        0,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TreePainter old) =>
      old.rings != rings ||
      old.season != season ||
      old.inkColor != inkColor ||
      !listEquals(old.lights, lights);
}
