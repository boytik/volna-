import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Типографика «Волны».
/// Manrope — заголовки (структурный, спокойный).
/// Nunito — тело (мягкий, округлый, как в Calm/Headspace — снижает «острое» восприятие).
class AppTypography {
  AppTypography._();

  static TextTheme build() {
    final body = GoogleFonts.nunitoTextTheme();
    final heading = GoogleFonts.manropeTextTheme();

    return TextTheme(
      displayLarge: heading.displayLarge?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.15,
      ),
      headlineLarge: heading.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      headlineMedium: heading.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      titleLarge: heading.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: body.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
      ),
      labelLarge: body.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
