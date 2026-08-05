import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Распознавание речи на самом телефоне.
///
/// Аудио не покидает устройство: система превращает речь в текст
/// локально и отдаёт нам только буквы. Файла записи не появляется
/// вовсе — ни временного, ни удаляемого потом.
///
/// Доступность спрашиваем у платформы **до** записи, через канал
/// `io.volna.volna/speech`: от ответа зависит, что написано на экране
/// про приватность, а такое обещание нельзя уточнять задним числом.
/// Сам плагин заранее не отвечает — он падает с ошибкой уже во время
/// записи, когда человек уже говорит.
class OnDeviceTranscribeService {
  OnDeviceTranscribeService({stt.SpeechToText? speech})
      : _speech = speech ?? stt.SpeechToText();

  static const _channel = MethodChannel('io.volna.volna/speech');
  static const localeId = 'ru-RU';

  /// 90 секунд — тот же потолок, что был у облачной записи.
  static const maxDuration = Duration(seconds: 90);

  /// Пауза, после которой система считает, что человек договорил.
  /// Взята с запасом: в тяжёлом разговоре паузы длинные, и обрывать
  /// на середине мысли нельзя.
  static const _pause = Duration(seconds: 6);

  final stt.SpeechToText _speech;
  bool? _supportsOnDevice;

  bool get isListening => _speech.isListening;

  /// Умеет ли этот телефон распознавать речь без сети.
  /// Результат кэшируется: пакет диктовки в середине сессии не появится.
  Future<bool> supportsOnDevice() async {
    if (_supportsOnDevice != null) return _supportsOnDevice!;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'supportsOnDevice',
        {'locale': localeId},
      );
      _supportsOnDevice = ok ?? false;
    } on PlatformException catch (e) {
      debugPrint('supportsOnDevice failed: $e');
      _supportsOnDevice = false;
    } on MissingPluginException {
      // Канала нет (тесты, web) — считаем, что не умеет.
      _supportsOnDevice = false;
    }
    return _supportsOnDevice!;
  }

  /// Готовит распознавание и просит разрешения. Возвращает false, если
  /// человек отказал или система не готова.
  Future<bool> prepare({void Function(String)? onError}) async {
    try {
      return await _speech.initialize(
        onError: (e) => onError?.call(e.errorMsg),
        // debugLogging намеренно выключен: логи распознавания содержат
        // то, что человек говорит.
        debugLogging: false,
      );
    } catch (e, st) {
      debugPrint('speech initialize failed: $e\n$st');
      return false;
    }
  }

  /// Слушает и отдаёт текст по мере распознавания. [onResult] вызывается
  /// многократно: сначала черновиками, в конце — окончательным текстом
  /// с `isFinal = true`.
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: stt.SpeechListenOptions(
        // Главное здесь: onDevice запрещает плагину уходить в сеть.
        onDevice: true,
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: maxDuration,
        pauseFor: _pause,
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
