import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Знак «уходит на сервер».
///
/// Стоит на «выговориться» и только там: это единственный внешний
/// вызов приложения (Azure OpenAI — распознавание речи и ответ).
/// Дневник, чек-ины и опросники его не имеют, и в этом весь смысл —
/// приватность видно глазом, а не только в тексте политики.
class LeavesDeviceMark extends StatelessWidget {
  const LeavesDeviceMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Этот раздел отправляет запись на сервер распознавания',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smR,
          border: Border.all(
            color: AppColors.accent,
            width: AppStroke.hairline,
          ),
        ),
        child: Text(
          'УХОДИТ НА СЕРВЕР',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.accentPress),
        ),
      ),
    );
  }
}
