import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Обёртка над flutter_sound.
///
/// На iOS пишем AAC в .aac, на вебе flutter_sound автоматически использует Opus в WebM.
/// Для облегчённого hold-to-talk сценария обнажаем три метода: start / stop / cancel + поток амплитуды.
class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _opened = false;
  String? _currentPath;
  String? _webBlobUrl;

  String? get currentPath => _currentPath;
  String? get webBlobUrl => _webBlobUrl;

  Stream<RecordingDisposition>? get _progress => _recorder.onProgress;

  Stream<double> amplitudeStream() {
    final stream = _progress;
    if (stream == null) return const Stream.empty();
    return stream.map((d) => d.decibels ?? -60);
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return true; // На вебе getUserMedia спросит сама.
    final s = await Permission.microphone.status;
    if (s.isGranted) return true;
    final r = await Permission.microphone.request();
    return r.isGranted;
  }

  Future<void> _ensureOpen() async {
    if (_opened) return;
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(
      const Duration(milliseconds: 120),
    );
    _opened = true;
  }

  Future<void> start() async {
    await _ensureOpen();

    String path;
    Codec codec;
    if (kIsWeb) {
      // На web путь игнорируется, flutter_sound вернёт URL после stop.
      path = 'vent.webm';
      codec = Codec.opusWebM;
    } else {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/vent_${DateTime.now().millisecondsSinceEpoch}.aac';
      codec = Codec.aacADTS;
    }
    _currentPath = path;

    await _recorder.startRecorder(
      toFile: path,
      codec: codec,
      sampleRate: 24000,
      numChannels: 1,
    );
  }

  /// Останавливает и возвращает байты (на native — читаем файл, на web — fetch blob).
  Future<Uint8List?> stop() async {
    if (!_opened) return null;
    final result = await _recorder.stopRecorder();

    if (kIsWeb) {
      // result — URL blob:https://...
      _webBlobUrl = result;
      return null;
    }

    final path = result ?? _currentPath;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    await _deleteFile(path);
    _currentPath = null;
    return bytes;
  }

  /// Прерывание записи. Обязательно удаляет временный файл: это интимная
  /// запись, оставлять её в tmp-директории нельзя.
  Future<void> cancel() async {
    String? path;
    try {
      if (_recorder.isRecording) path = await _recorder.stopRecorder();
    } catch (_) {}

    _webBlobUrl = null;
    if (kIsWeb) {
      _currentPath = null;
      return;
    }

    await _deleteFile(path ?? _currentPath);
    _currentPath = null;
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      if (_opened) await _recorder.closeRecorder();
    } catch (_) {}
    _opened = false;
  }
}
