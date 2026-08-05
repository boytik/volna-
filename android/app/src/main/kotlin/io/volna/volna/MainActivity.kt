package io.volna.volna

import android.os.Build
import android.speech.SpeechRecognizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Тот же вопрос, что и на iOS: умеет ли телефон распознавать речь
    // без сети. Ответ нужен до записи — от него зависит текст про
    // приватность на экране.
    //
    // На Android офлайн-распознавание появилось только в API 31, и даже
    // там доступность зависит от производителя. Поэтому «нет» здесь
    // встречается чаще, чем на iOS, и откат в облако должен работать
    // честно, а не как заглушка.
    private val channelName = "io.volna.volna/speech"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supportsOnDevice" -> result.success(supportsOnDevice())
                    else -> result.notImplemented()
                }
            }
    }

    private fun supportsOnDevice(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        return try {
            SpeechRecognizer.isOnDeviceRecognitionAvailable(applicationContext)
        } catch (e: Throwable) {
            false
        }
    }
}
