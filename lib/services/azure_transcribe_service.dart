import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/secrets.dart';

/// Транскрибация голоса через Azure OpenAI (gpt-4o-transcribe или whisper).
class AzureTranscribeService {
  /// Принимает либо нативные байты, либо web blob URL (одно из двух обязательно).
  Future<String?> transcribe({
    Uint8List? bytes,
    String? webBlobUrl,
    String filename = 'audio.m4a',
  }) async {
    Uint8List? data = bytes;

    if (data == null && webBlobUrl != null) {
      final res = await http.get(Uri.parse(webBlobUrl));
      if (res.statusCode != 200) {
        debugPrint('Blob fetch failed: ${res.statusCode}');
        return null;
      }
      data = res.bodyBytes;
    }

    if (data == null || data.isEmpty) return null;

    final url = Uri.parse(
      '$azureOpenAiEndpoint/openai/deployments/$transcribeDeployment'
      '/audio/transcriptions?api-version=$transcribeApiVersion',
    );

    final request = http.MultipartRequest('POST', url)
      ..headers['api-key'] = azureOpenAiApiKey
      ..fields['language'] = 'ru'
      ..fields['response_format'] = 'json'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          data,
          filename: filename,
        ),
      );

    try {
      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        debugPrint(
            'Azure transcribe ${response.statusCode}: ${response.body}');
        return null;
      }
      final body = utf8.decode(response.bodyBytes);
      final json = jsonDecode(body);
      if (json is Map && json['text'] is String) {
        return (json['text'] as String).trim();
      }
      return null;
    } catch (e, st) {
      debugPrint('Transcribe failed: $e\n$st');
      return null;
    }
  }
}
