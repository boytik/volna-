import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/content/crisis_keywords.dart';

/// Единая точка проверки свободного текста на кризис.
///
/// Вызывается из КАЖДОГО места, где пользователь вводит свой текст:
/// голосовое «Выговорись» (после расшифровки), текстовое «Выговорись»,
/// дневник. Раньше проверка стояла только в голосовом пути — а текстовый
/// как раз тот, куда приложение уводит при отсутствии сети и микрофона.
///
/// Возвращает true, если кризис распознан и пользователь уже уведён
/// на `/crisis` — вызывающий код в этом случае ничего больше не делает.
bool guardCrisis(
  BuildContext context,
  String text, {
  /// true — заменить текущий экран кризисным (для форм, откуда возвращаться некуда).
  bool replace = false,
}) {
  final crisis = CrisisDetector.detect(text);
  if (crisis == null) return false;

  final location = '/crisis?category=${crisis.name}';
  if (replace) {
    context.pushReplacement(location);
  } else {
    context.push(location);
  }
  return true;
}
