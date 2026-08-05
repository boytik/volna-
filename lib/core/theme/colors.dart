import 'package:flutter/material.dart';

/// Палитра «Волны».
/// Базируется на психологии цвета из ТЗ:
/// — персиковый/абрикосовый = забота, тепло, снижает кортизол
/// — терракотовый = действие без спешки
/// — шалфейный = спокойствие, дыхание
/// — золотистый = надежда, утренние практики
/// — коралловый = мягкое предупреждение (SOS, но не пугающий красный)
class AppColors {
  AppColors._();

  // Фоны
  static const cream = Color(0xFFFAF6F1);
  static const creamDeep = Color(0xFFF1E9DD);

  // Тёплая основа (забота)
  static const peach = Color(0xFFF5C9A6);
  static const peachSoft = Color(0xFFFADDC2);

  // Акцент (действие)
  static const terracotta = Color(0xFFC97B5C);
  static const terracottaDeep = Color(0xFFB46245);

  // Спокойные зоны (дыхание, заземление)
  static const sage = Color(0xFFA8B89E);
  static const sageDeep = Color(0xFF7D9171);

  // Утренние квесты, надежда
  static const saffron = Color(0xFFE8B85C);

  // SOS / границы (мягкий коралл, не красный)
  static const coral = Color(0xFFE89B8C);

  // Текст
  static const textPrimary = Color(0xFF2E2A26);
  static const textSecondary = Color(0xFF6B6259);
  static const textMuted = Color(0xFF9A9189);
}
