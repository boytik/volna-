import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Типографика «Волны» — система «Печатная страница».
///
/// Ровно два шрифта на всё приложение:
///   Literata   — голос. Антиква, спроектированная для чтения с экрана,
///                с полной кириллицей. Крупный русский текст в ней
///                читается как чья-то речь, а не как системное
///                сообщение. Контент написан психологом — Literata
///                обращается с ним как с текстом, а не как с UI-копирайтом.
///   Golos Text — служебное. Гротеск «Паратайпа», спроектированный
///                *от* кириллицы, а не адаптированный под неё.
///
/// Контраст «антиква = голос / гротеск = служебное» и есть иерархия;
/// третий шрифт не нужен.
///
/// Ушли: Nunito (округлость — тот самый «милый» регистр, который
/// выгоревший родитель читает как снисхождение) и Manrope.
class AppTypography {
  AppTypography._();

  /// Микро-метка: 11px, tracking 0.16em. Регистр поднимается в месте
  /// использования (`.toUpperCase()`), не здесь.
  static TextStyle micro({Color? color}) => GoogleFonts.golosText(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 11 * 0.16,
        height: 1.3,
        color: color ?? AppColors.inkQuiet,
      );

  /// Голос психолога и дневниковые записи — всегда антиквой.
  static TextStyle voice({
    double size = 20,
    Color? color,
    FontStyle? fontStyle,
  }) =>
      GoogleFonts.literata(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color ?? AppColors.ink,
        fontStyle: fontStyle,
      );

  static TextTheme build({bool night = false}) {
    final ink = night ? AppColors.nightInk : AppColors.ink;
    final body = night ? AppColors.nightInkBody : AppColors.inkBody;
    final soft = night ? AppColors.nightInkSoft : AppColors.inkSoft;
    final quiet = night ? AppColors.nightInkQuiet : AppColors.inkQuiet;

    TextStyle serif(double size, double lineHeight) => GoogleFonts.literata(
          fontSize: size,
          fontWeight: FontWeight.w500,
          height: lineHeight / size,
          letterSpacing: -0.015 * size,
          color: ink,
        );

    TextStyle sans(
      double size,
      double lineHeight, {
      FontWeight weight = FontWeight.w400,
      required Color color,
    }) =>
        GoogleFonts.golosText(
          fontSize: size,
          fontWeight: weight,
          height: lineHeight / size,
          color: color,
        );

    return TextTheme(
      // ── Голос ──────────────────────────────────────────────
      displayLarge: serif(32, 40),
      headlineLarge: serif(26, 34),
      headlineMedium: serif(22, 30),
      titleLarge: serif(20, 28),

      // ── Служебное ──────────────────────────────────────────
      bodyLarge: sans(17, 26, color: body),
      bodyMedium: sans(15, 23, color: soft),
      bodySmall: sans(13, 18, color: quiet),
      labelLarge: sans(16, 22, weight: FontWeight.w600, color: body),
      labelSmall: GoogleFonts.golosText(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 11 * 0.16,
        height: 1.3,
        color: quiet,
      ),
    );
  }
}
