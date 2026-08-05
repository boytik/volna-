import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/tokens.dart';

/// Полоса «Мне сейчас плохо» — основной SOS-вход.
/// Подпись из ТЗ: «Мне тяжело» (вместо громкого «SOS»).
///
/// Плоская коралловая полоса вровень с краями экрана: радиус 0,
/// ни тени, ни градиента, ни свечения. Как приклеенная полоска
/// цветной бумаги.
///
/// Анимации нет намеренно. Раньше кнопка пульсировала бесконечно
/// (`repeat(reverse: true)`) и игнорировала «уменьшение движения» —
/// постоянное требование внимания на главном экране приложения для
/// людей в остром стрессе. Заметность даёт размер, цвет и положение,
/// а не движение.
class SosButton extends StatelessWidget {
  const SosButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Полоса доходит до физического края экрана, а безопасную зону
    // забирает себе внутренним отступом. Обернуть виджет в SafeArea
    // нельзя: под полосой останется кремовая щель, и «приклеенная
    // полоска бумаги» превратится в плавающую панель.
    final inset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: AppColors.sos,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56 + inset,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.axis,
              right: AppSpacing.axis,
              bottom: inset,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Мне сейчас плохо',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.sosInk,
                        ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.sosInk,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
