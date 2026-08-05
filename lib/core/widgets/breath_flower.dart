import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Цветок дыхания в духе Apple Watch: шесть лепестков расходятся на
/// вдохе, сходятся на выдохе, и всё это медленно вращается.
///
/// Почему не один круг: расширяющийся круг — главное клише категории,
/// и он замирает на задержках. В «Квадрате» задержки занимают половину
/// времени, и человек оставался наедине со счётом. Лепестки вращаются
/// всегда, взгляду есть за что держаться.
///
/// Заливка плоская, с прозрачностью: перекрытия лепестков сами дают
/// глубину, поэтому ни градиента, ни тени не нужно.
///
/// Здесь только отрисовка. Ритм задаёт снаружи: в «Квадрате» — фазовый
/// контроллер практики, в остальных дыхательных техниках —
/// [AmbientBreathFlower], который дышит сам.
class BreathFlower extends StatelessWidget {
  const BreathFlower({
    super.key,
    required this.level,
    required this.rotation,
    this.size = 240,
  });

  /// 0 — лепестки собраны в центре, 1 — разошлись.
  final double level;
  final double rotation;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FlowerPainter(level: level, rotation: rotation),
      ),
    );
  }
}

/// Цветок, который дышит сам. Для дыхательных техник, у которых нет
/// своего фазового контроллера: «Двойной вдох», «Удлинённый выдох».
///
/// Темп берётся из самой техники — у удлинённого выдоха выдох вдвое
/// длиннее вдоха, и цветок должен показывать именно это, иначе он
/// будет спорить с текстом инструкции.
class AmbientBreathFlower extends StatefulWidget {
  const AmbientBreathFlower({
    super.key,
    this.inhale = const Duration(seconds: 4),
    this.exhale = const Duration(seconds: 6),
    this.size = 160,
  });

  final Duration inhale;
  final Duration exhale;
  final double size;

  @override
  State<AmbientBreathFlower> createState() => _AmbientBreathFlowerState();
}

class _AmbientBreathFlowerState extends State<AmbientBreathFlower>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _spin;
  late final Animation<double> _level;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: widget.inhale + widget.exhale,
    );
    _level = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: widget.inhale.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: widget.exhale.inMilliseconds.toDouble(),
      ),
    ]).animate(_breath);

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Здесь движение — часть практики, но при «уменьшении движения»
    // мы всё равно замираем: инструкция шага остаётся текстом и
    // работает без анимации.
    if (AppMotion.reduced(context)) {
      _breath.stop();
      _spin.stop();
      _breath.value = 0.5;
    } else {
      if (!_breath.isAnimating) _breath.repeat();
      if (!_spin.isAnimating) _spin.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _spin]),
      builder: (_, _) => BreathFlower(
        level: _level.value,
        rotation: _spin.value * 2 * math.pi,
        size: widget.size,
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  _FlowerPainter({required this.level, required this.rotation});

  final double level;
  final double rotation;

  static const _petals = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final petalR = r * 0.42;
    // На нуле лепестки почти слиты — цветок не исчезает и не схлопывается
    // в точку. На единице касаются внешнего края.
    final distance = (r - petalR) * (0.18 + 0.82 * level);

    final paint = Paint()
      ..color = AppColors.markedWash.withValues(alpha: 0.42)
      ..isAntiAlias = true;

    for (var i = 0; i < _petals; i++) {
      final angle = rotation + i * 2 * math.pi / _petals;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        petalR,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter old) =>
      old.level != level || old.rotation != rotation;
}
