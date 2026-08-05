import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Открытие внешних ссылок (tel:, https:) с понятным фолбэком.
///
/// Голый `launchUrl` бросает исключение, если обработчика нет (симулятор, веб,
/// iPad без сим-карты). Для кнопки телефона доверия это недопустимо — человек
/// в кризисе должен увидеть номер, даже если позвонить из приложения не вышло.
Future<void> openExternal(
  BuildContext context,
  String url, {
  String? fallbackMessage,
}) async {
  final uri = Uri.tryParse(url);
  var ok = false;

  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }

  if (ok || !context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(fallbackMessage ?? _defaultMessage(uri)),
      duration: const Duration(seconds: 6),
    ),
  );
}

String _defaultMessage(Uri? uri) {
  if (uri?.scheme == 'tel') {
    // Номер показываем текстом — его можно набрать вручную.
    return 'Не получилось открыть звонилку. Номер: ${uri!.path}';
  }
  return 'Не получилось открыть ссылку';
}
