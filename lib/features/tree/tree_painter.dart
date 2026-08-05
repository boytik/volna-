import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

enum TreeMood { vibrant, pale, sleeping }

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
    required this.growth,
    required this.mood,
    required this.season,
  });

  final double growth;
  final TreeMood mood;
  final Season season;

  Color _tint(Color base) {
    switch (mood) {
      case TreeMood.vibrant:
        return base;
      case TreeMood.pale:
        return Color.lerp(base, AppColors.cream, 0.45) ?? base;
      case TreeMood.sleeping:
        return Color.lerp(base, AppColors.textMuted, 0.55) ?? base;
    }
  }

  /// Цвета листьев под сезон.
  ({Color dark, Color light}) _leafColors() {
    switch (season) {
      case Season.spring:
        return (
          dark: _tint(AppColors.sageDeep),
          light: _tint(AppColors.sage),
        );
      case Season.summer:
        return (
          dark: _tint(const Color(0xFF4A6B3F)),
          light: _tint(const Color(0xFF7BA060)),
        );
      case Season.autumn:
        return (
          dark: _tint(const Color(0xFFB85B2A)),
          light: _tint(const Color(0xFFE8A856)),
        );
      case Season.winter:
        return (
          dark: _tint(AppColors.sageDeep),
          light: _tint(AppColors.sage),
        );
    }
  }

  Color _flowerColor() {
    switch (season) {
      case Season.spring:
        return _tint(const Color(0xFFE8A8C8));
      case Season.summer:
        return _tint(AppColors.saffron);
      case Season.autumn:
        return _tint(const Color(0xFFD9742A));
      case Season.winter:
        return _tint(const Color(0xFFE8E8F0));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height * 0.86;

    _paintPot(canvas, cx, groundY, size);
    _paintGround(canvas, cx, groundY, size);

    if (growth <= 0) return;

    final trunkBase = Offset(cx, groundY);
    final maxTrunkH = size.height * 0.62;
    final trunkH = maxTrunkH * growth.clamp(0.05, 1.0);
    final trunkTop = Offset(cx, groundY - trunkH);

    _paintTrunk(canvas, trunkBase, trunkTop);

    if (mood == TreeMood.sleeping && growth < 0.5) {
      _paintSleepingDots(canvas, trunkTop);
      return;
    }

    _paintCrown(canvas, trunkTop, size);

    if (season == Season.winter) {
      _paintSnow(canvas, trunkTop, size);
    }
    if (season == Season.autumn) {
      _paintFallenLeaves(canvas, groundY, size);
    }
  }

  void _paintPot(Canvas canvas, double cx, double groundY, Size size) {
    final potTop = groundY;
    final potW = size.width * 0.32;
    final potH = size.height * 0.10;
    final rect = Rect.fromCenter(
      center: Offset(cx, potTop + potH / 2),
      width: potW,
      height: potH,
    );
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _tint(AppColors.terracotta),
          _tint(AppColors.terracottaDeep),
        ],
      ).createShader(rect);
    final path = Path()
      ..moveTo(rect.left + 6, rect.top)
      ..lineTo(rect.right - 6, rect.top)
      ..lineTo(rect.right - 14, rect.bottom)
      ..lineTo(rect.left + 14, rect.bottom)
      ..close();
    canvas.drawPath(path, paint);

    final rim = Paint()
      ..color = _tint(AppColors.terracottaDeep).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(rect.left + 4, rect.top + 4),
      Offset(rect.right - 4, rect.top + 4),
      rim,
    );
  }

  void _paintGround(Canvas canvas, double cx, double groundY, Size size) {
    final paint = Paint()
      ..color = _tint(const Color(0xFF8B6F4E)).withValues(alpha: 0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + 2),
        width: size.width * 0.30,
        height: 8,
      ),
      paint,
    );
  }

  void _paintTrunk(Canvas canvas, Offset base, Offset top) {
    final thickness = (4 + 6 * growth).clamp(2.0, 10.0);
    final color = _tint(const Color(0xFF7B5B3E));

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;

    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + 6 * growth,
        (base.dy + top.dy) / 2,
        top.dx,
        top.dy,
      );
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = thickness;
    canvas.drawPath(path, stroke);

    canvas.drawCircle(top, thickness / 2.2, paint);
  }

  void _paintCrown(Canvas canvas, Offset trunkTop, Size size) {
    final colors = _leafColors();
    final flowerColor = _flowerColor();
    final budColor = _tint(AppColors.peach);

    final crownRadius = 10 + 50 * growth;

    // Зимой листьев гораздо меньше — облетели
    final isWinter = season == Season.winter;

    if (growth < 0.25) {
      _drawLeaf(canvas, trunkTop.translate(-8, -6), 8, colors.dark, -0.5);
      if (!isWinter) {
        _drawLeaf(canvas, trunkTop.translate(8, -10), 9, colors.light, 0.5);
      }
      return;
    }

    final rng = math.Random(42);
    final baseLeafCount = (8 + 22 * growth).round();
    // Зимой — только 30% листьев.
    final leafCount = isWinter ? (baseLeafCount * 0.3).round() : baseLeafCount;

    for (var i = 0; i < leafCount; i++) {
      final angle = (i / leafCount.clamp(1, 999)) * math.pi * 2;
      final r = crownRadius * (0.55 + rng.nextDouble() * 0.45);
      final dx = math.cos(angle) * r;
      final dy = math.sin(angle) * r * 0.8 - crownRadius * 0.3;
      final pos = trunkTop.translate(dx, dy);
      final leafSize = 6 + rng.nextDouble() * 5;
      final color = i.isEven ? colors.dark : colors.light;
      _drawLeaf(canvas, pos, leafSize, color, angle);
    }

    // Бутоны — только летом и осенью при достаточном росте.
    if (growth >= 0.5 && (season == Season.summer || season == Season.autumn)) {
      final budCount = ((growth - 0.5) * 8).round();
      for (var i = 0; i < budCount; i++) {
        final angle = i * (math.pi * 2 / 6);
        final r = crownRadius * 0.7;
        final pos = trunkTop.translate(
          math.cos(angle) * r,
          math.sin(angle) * r * 0.8 - crownRadius * 0.3,
        );
        canvas.drawCircle(
          pos,
          3 + (growth - 0.5) * 4,
          Paint()..color = budColor,
        );
      }
    }

    // Весной — цветение раньше (с 0.4 а не 0.8).
    final flowerThreshold = season == Season.spring ? 0.4 : 0.8;
    if (growth >= flowerThreshold) {
      final glow = Paint()
        ..color = flowerColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(
        trunkTop.translate(0, -crownRadius * 0.3),
        crownRadius * 1.2,
        glow,
      );

      final flowerCount = season == Season.spring ? 7 : 5;
      for (var i = 0; i < flowerCount; i++) {
        final angle = i * (math.pi * 2 / flowerCount) - math.pi / 2;
        final r = crownRadius * 0.6;
        final pos = trunkTop.translate(
          math.cos(angle) * r,
          math.sin(angle) * r * 0.8 - crownRadius * 0.3,
        );
        _drawFlower(canvas, pos, 6, flowerColor);
      }
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double size,
    Color color,
    double rotation,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, -size)
      ..quadraticBezierTo(size * 0.8, 0, 0, size)
      ..quadraticBezierTo(-size * 0.8, 0, 0, -size)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawFlower(Canvas canvas, Offset center, double size, Color color) {
    final petal = Paint()..color = color;
    for (var i = 0; i < 5; i++) {
      final angle = i * (math.pi * 2 / 5);
      final pos = center.translate(
        math.cos(angle) * size * 0.55,
        math.sin(angle) * size * 0.55,
      );
      canvas.drawCircle(pos, size * 0.5, petal);
    }
    canvas.drawCircle(
      center,
      size * 0.35,
      Paint()..color = AppColors.cream,
    );
  }

  void _paintSleepingDots(Canvas canvas, Offset trunkTop) {
    final paint = Paint()..color = _tint(AppColors.sageDeep);
    canvas.drawCircle(trunkTop.translate(-6, -4), 4, paint);
    canvas.drawCircle(trunkTop.translate(6, -2), 3, paint);
  }

  /// Снежинки на ветках зимой
  void _paintSnow(Canvas canvas, Offset trunkTop, Size size) {
    final rng = math.Random(7);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final crownR = 10 + 50 * growth;
    for (var i = 0; i < 8; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final r = rng.nextDouble() * crownR;
      final pos = trunkTop.translate(
        math.cos(angle) * r,
        math.sin(angle) * r * 0.8 - crownR * 0.4,
      );
      canvas.drawCircle(pos, 1.6 + rng.nextDouble(), paint);
    }
  }

  /// Опавшие листья у горшка осенью
  void _paintFallenLeaves(Canvas canvas, double groundY, Size size) {
    final rng = math.Random(11);
    final colors = [
      _tint(const Color(0xFFB85B2A)),
      _tint(const Color(0xFFE8A856)),
      _tint(const Color(0xFFD9742A)),
    ];
    final cx = size.width / 2;
    for (var i = 0; i < 5; i++) {
      final dx = (rng.nextDouble() - 0.5) * size.width * 0.6;
      final pos = Offset(cx + dx, groundY + 12 + rng.nextDouble() * 8);
      final color = colors[rng.nextInt(colors.length)];
      _drawLeaf(canvas, pos, 4 + rng.nextDouble() * 3,
          color, rng.nextDouble() * math.pi);
    }
  }

  @override
  bool shouldRepaint(covariant TreePainter old) =>
      old.growth != growth || old.mood != mood || old.season != season;
}
