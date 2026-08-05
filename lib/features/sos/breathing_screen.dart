import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/widgets/helped_button.dart';
import '../../data/local/toolbox_storage.dart';

/// Дыхание «Квадрат»: вдох 4с — задержка 4с — выдох 4с — задержка 4с.
/// 5 циклов = ~80 секунд. Анимация: круг расширяется на вдохе, держится,
/// сжимается на выдохе, держится. Лёгкая вибрация на смене фазы.
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
    with SingleTickerProviderStateMixin {
  static const _totalCycles = 5;

  late final AnimationController _controller;
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
    _startPhase();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.cream,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          Text(
            'Цикл $_cycle из $_totalCycles',
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, _) {
              return _BreathCircle(scale: _controller.value, phase: _phase);
            },
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
                color: AppColors.sage.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 64,
                color: AppColors.sageDeep,
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
              _startPhase();
            },
            child: const Text('Ещё раз'),
          ),
        ],
      ),
    );
  }
}

class _BreathCircle extends StatelessWidget {
  const _BreathCircle({required this.scale, required this.phase});

  final double scale;
  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    final size = 220.0 * scale;

    return SizedBox(
      width: 240,
      height: 240,
      child: Center(
        child: Container(
          width: size,
          height: size,
          // Плоская заливка без градиента и свечения: теней в системе
          // нет. Замена круга на линию горизонта («вдох поднимает
          // горизонт») зафиксирована в DESIGN.md и отложена.
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.markedWash,
          ),
        ),
      ),
    );
  }
}
