import 'package:flutter/material.dart';

import 'colors.dart';
import 'tokens.dart';
import 'typography.dart';

/// Тема «Волны» — система «Печатная страница».
///
/// Теней нет вовсе: группировку держат волосяные линейки, отступы
/// и кегль. Радиусов три (0 / 4 / 12), см. [AppRadius].
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(night: false);

  static ThemeData dark() => _build(night: true);

  static ThemeData _build({required bool night}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: night ? Brightness.dark : Brightness.light,
    );

    final paper = night ? AppColors.night : AppColors.paper;
    final lift = night ? AppColors.nightLift : AppColors.paperLift;
    final rule = night ? AppColors.nightRule : AppColors.rule;
    final ink = night ? AppColors.nightInk : AppColors.ink;
    final body = night ? AppColors.nightInkBody : AppColors.inkBody;
    final soft = night ? AppColors.nightInkSoft : AppColors.inkSoft;
    final accent = night ? AppColors.nightAccent : AppColors.accent;

    return base.copyWith(
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme(
        brightness: night ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: night ? AppColors.night : AppColors.paperLift,
        secondary: AppColors.marked,
        onSecondary: AppColors.paperLift,
        // В эмоциональном контуре ошибок не существует. Красного в
        // системе нет: error нужен только для технических сбоев
        // (экспорт/импорт, сеть).
        error: AppColors.accentPress,
        onError: AppColors.paperLift,
        surface: paper,
        onSurface: body,
        surfaceContainerHighest: lift,
        outline: rule,
        outlineVariant: rule,
      ),
      textTheme: AppTypography.build(night: night),
      dividerTheme: DividerThemeData(
        color: rule,
        thickness: AppStroke.hairline,
        space: AppStroke.hairline,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        // Чистый белый на кремовом читается как дырка.
        color: lift,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smR,
          side: BorderSide(color: rule, width: AppStroke.hairline),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: night ? AppColors.night : AppColors.paperLift,
          minimumSize: const Size.fromHeight(56),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smR),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        // Отказ — это полноценная кнопка, а не серая ссылка внизу экрана.
        style: OutlinedButton.styleFrom(
          foregroundColor: soft,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: rule, width: AppStroke.hairline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.smR),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: night ? AppColors.nightAccent : AppColors.accentPress,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: lift,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
