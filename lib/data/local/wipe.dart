import 'package:shared_preferences/shared_preferences.dart';

/// Полное удаление всех локальных данных пользователя.
///
/// Все сторы приложения лежат в одном SharedPreferences, поэтому достаточно
/// очистить его целиком — но сначала нужно снять запланированные уведомления,
/// иначе пуш о переоткрытии конверта придёт к уже удалённой записи.
///
/// Возвращает управление после того, как всё стёрто: вызывающий экран должен
/// увести пользователя на онбординг.
Future<void> wipeAllLocalData({
  required Future<void> Function() cancelNotifications,
}) async {
  await cancelNotifications();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}
