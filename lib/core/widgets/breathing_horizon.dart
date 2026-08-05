import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Тихий ритм дыхания: короткая волосяная линия медленно поднимается
/// и опускается. Горизонт над водой.
///
/// Это не упражнение и не кнопка. Человек приходит сюда взвинченным,
/// и ритм на 6 дыханий в минуту начинает его успокаивать ещё до того,
/// как он выберет технику. Со-регуляция, а не привлечение внимания —
/// и в этом вся разница с пульсацией, которую мы убрали с кнопки SOS:
/// та говорила «нажми меня», эта не просит ничего.
///
/// Круг здесь был бы главным клише категории (см. DESIGN.md), поэтому
/// горизонт. Заодно это и есть название приложения.
///
/// Вдох 4 секунды, выдох 6 — выдох длиннее вдоха, так работает
/// парасимпатика. При включённом «уменьшении движения» линия просто
/// стоит на середине.
class BreathingHorizon extends StatefulWidget {
  const BreathingHorizon({super.key, this.height = 34});

  final double height;

  static const inhale = Duration(seconds: 4);
  static const exhale = Duration(seconds: 6);

  @override
  State<BreathingHorizon> createState() => _BreathingHorizonState();
}

class _BreathingHorizonState extends State<BreathingHorizon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _level;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: BreathingHorizon.inhale + BreathingHorizon.exhale,
    );
    // 0 — низкий горизонт (выдох), 1 — высокий (вдох).
    _level = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: BreathingHorizon.inhale.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: BreathingHorizon.exhale.inMilliseconds.toDouble(),
      ),
    ]).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Единственная зацикленная анимация в приложении, и она обязана
    // молчать, когда система просит меньше движения.
    if (AppMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Только линия, без заливки под ней. Тонированная область меняла
    // высоту и читалась серым прямоугольником — скелетоном загрузки,
    // а не дыханием. Линия и есть словарь этой системы: она просто
    // движется там, где остальные стоят.
    //
    // Ширина неполная — иначе движущаяся линия во весь экран похожа
    // на разделитель, который глючит.
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _level,
        builder: (context, _) {
          // Ход около 20pt: достаточно, чтобы за ним следовало дыхание,
          // и мало, чтобы он не требовал внимания.
          final top = widget.height * (0.78 - 0.56 * _level.value);
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: top,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.55,
                  child: Container(
                    height: AppStroke.hairline,
                    color: AppColors.markedWash,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
