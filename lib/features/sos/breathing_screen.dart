import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/breath_flower.dart';
import '../../core/widgets/helped_button.dart';
import '../../data/local/toolbox_storage.dart';

/// Дыхание «Квадрат»: вдох 4с — задержка 4с — выдох 4с — задержка 4с.
/// 5 циклов = ~80 секунд. Цветок из шести лепестков расходится на вдохе,
/// сходится на выдохе и всё время медленно вращается — на задержках
/// вращение продолжается, поэтому взгляду есть за чем следить, пока
/// человек не дышит. Лёгкая вибрация на смене фазы.
enum _Phase {
  inhale('Вдох', 4),
  holdIn('Задержи', 4),
  exhale('Выдох', 4),
  holdOut('Задержи', 4);

  const _Phase(this.label, this.seconds);
  final String label;
  final int seconds;

  _Phase get next => _Phase.values[(index + 1) % _Phase.values.length];
}

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  static const _totalCycles = 5;

  late final AnimationController _controller;
  /// Вращение цветка. Отдельно от фазового контроллера: тот ходит
  /// туда-обратно, и цветок на нём качался бы, а не вращался.
  late final AnimationController _spin;
  _Phase _phase = _Phase.inhale;
  int _cycle = 1;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _phase.seconds),
      lowerBound: 0.5,
      upperBound: 1.0,
    );
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    );
    _startPhase();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Расхождение лепестков — это само упражнение, оно остаётся всегда.
    // Вращение декоративно, поэтому при «уменьшении движения» молчит.
    if (AppMotion.reduced(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating && !_finished) {
      _spin.repeat();
    }
  }

  void _startPhase() {
    HapticFeedback.lightImpact();
    _controller.duration = Duration(seconds: _phase.seconds);

    switch (_phase) {
      case _Phase.inhale:
        _controller.forward(from: _controller.value);
      case _Phase.exhale:
        _controller.reverse(from: _controller.value);
      case _Phase.holdIn:
      case _Phase.holdOut:
        _controller.stop();
    }

    _timer?.cancel();
    _timer = Timer(Duration(seconds: _phase.seconds), _onPhaseEnd);
  }

  void _onPhaseEnd() {
    if (!mounted) return;
    if (_phase == _Phase.holdOut) {
      if (_cycle >= _totalCycles) {
        _spin.stop();
        setState(() => _finished = true);
        HapticFeedback.mediumImpact();
        return;
      }
      setState(() => _cycle++);
    }
    setState(() => _phase = _phase.next);
    _startPhase();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _finished ? _buildFinished(theme) : _buildBreathing(theme),
      ),
    );
  }

  Widget _buildBreathing(ThemeData theme) {
    // Center обязателен. Column в Padding получает нежёсткие ограничения
    // и сжимается по ширине до самого широкого ребёнка — здесь это
    // цветок в 240pt. Без Center колонка прижималась к левому краю, и
    // весь экран уезжал влево на 56pt.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Center(
        child: Column(
          children: [
            Text(
              'Цикл $_cycle из $_totalCycles',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: Listenable.merge([_controller, _spin]),
              builder: (_, _) => BreathFlower(
                // Контроллер ходит 0.5..1.0 — приводим к 0..1.
                level: (_controller.value - 0.5) * 2,
                rotation: _spin.value * 2 * math.pi,
              ),
            ),
            const SizedBox(height: 40),
            Text(_phase.label, style: theme.textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              '${_phase.seconds} счёта',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinished(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.markedWash.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 64,
                color: AppColors.marked,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Ты сделал шаг\nиз паники в тишину',
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Серьёзно. Это работает. Не потому что ты идеальный — '
            'а потому что ты вернулся к дыханию.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          const Center(child: HelpedButton(tool: ToolKey.breathing)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Вернуться'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _cycle = 1;
                _phase = _Phase.inhale;
                _finished = false;
              });
              if (!AppMotion.reduced(context)) _spin.repeat();
              _startPhase();
            },
            child: const Text('Ещё раз'),
          ),
        ],
      ),
    );
  }
}
