package com.pavelhegai.volna

import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    // Тот же вопрос, что и на iOS: умеет ли телефон распознавать речь
    // без сети для нужного языка. Ответ нужен до записи — от него
    // зависит текст про приватность на экране.
    //
    // На Android офлайн-распознавание появилось только в API 31, и даже
    // там доступность зависит от производителя. Поэтому «нет» здесь
    // встречается чаще, чем на iOS, и откат в облако должен работать
    // честно, а не как заглушка.
    //
    // Имя канала историческое, к bundle id отношения не имеет.
    private val channelName = "io.volna.volna/speech"

    /// Сколько ждём ответа системы, прежде чем считать, что его не будет.
    private val supportTimeoutMs = 3000L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "supportsOnDevice" -> {
                        val locale = call.argument<String>("locale") ?: "ru-RU"
                        supportsOnDevice(locale, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Умеет ли телефон распознавать речь на устройстве для этого языка.
     *
     * Отвечает `false`, если офлайн-движка нет вовсе или если система
     * прямо сказала, что нужного языка у неё нет.
     *
     * Раньше здесь стоял голый `isOnDeviceRecognitionAvailable()`, а он
     * отвечает «есть ли офлайн-движок вообще», без привязки к языку.
     * На телефоне с движком, но без русского пакета получался ложный
     * «умею»: знак «уходит с телефона» не показывался, а распознавание
     * падало уже во время записи — то есть обещание про приватность
     * выдавалось авансом и не выполнялось.
     *
     * Список языков отдаёт только `checkRecognitionSupport` (API 33+).
     * На 31–32 проверить язык нечем, и там мы отвечаем оптимистично —
     * так же, как отвечали раньше.
     *
     * Асимметрия намеренная, и вот почему. Ложное «умею» аудио никуда
     * не сливает: распознавание просто сорвётся, и voice_vent_screen
     * покажет ошибку с предложением написать текстом — в облако он при
     * этом не уходит. А вот ложное «не умею» отправляет человека ровно
     * туда, где аудио покидает телефон. Значит осторожность здесь
     * дороже обходится, чем оптимизм, и молчать надо в сторону «умею».
     *
     * На 33+ мы не гадаем, а знаем: если русского в списке нет,
     * локальный путь гарантированно сорвётся, и честный `false`
     * оставляет человеку рабочий облачный путь — со знаком «уходит
     * с телефона» на месте.
     */
    private fun supportsOnDevice(localeId: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.success(false)
            return
        }

        val available = try {
            SpeechRecognizer.isOnDeviceRecognitionAvailable(applicationContext)
        } catch (e: Throwable) {
            false
        }
        if (!available) {
            result.success(false)
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }

        checkLanguage(localeId, result)
    }

    @RequiresApi(Build.VERSION_CODES.TIRAMISU)
    private fun checkLanguage(localeId: String, result: MethodChannel.Result) {
        // Ответить можно ровно один раз: колбэк системы и таймаут
        // гонятся друг с другом.
        val answered = AtomicBoolean(false)
        val main = Handler(Looper.getMainLooper())
        var recognizer: SpeechRecognizer? = null

        fun answer(supported: Boolean) {
            if (answered.getAndSet(true)) return
            main.post {
                recognizer?.destroy()
                result.success(supported)
            }
        }

        // Движок на месте, но система не ответила про язык. Это неведение,
        // а не знание, — падаем в ту же оптимистичную сторону, что и на 31–32.
        val timeout = Runnable { answer(true) }
        main.postDelayed(timeout, supportTimeoutMs)

        try {
            recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(applicationContext)
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
                .putExtra(
                    RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                    RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
                )
                .putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)

            recognizer.checkRecognitionSupport(
                intent,
                mainExecutor,
                object : RecognitionSupportCallback {
                    override fun onSupportResult(support: RecognitionSupport) {
                        main.removeCallbacks(timeout)
                        answer(matchesLanguage(support.supportedOnDeviceLanguages, localeId))
                    }

                    override fun onError(error: Int) {
                        main.removeCallbacks(timeout)
                        answer(false)
                    }
                },
            )
        } catch (e: Throwable) {
            main.removeCallbacks(timeout)
            answer(false)
        }
    }

    /**
     * Система отдаёт теги вида `ru-RU`, `ru_RU` или просто `ru` —
     * сравниваем по языку, а не по полному совпадению.
     */
    private fun matchesLanguage(supported: List<String>, localeId: String): Boolean {
        val wanted = localeId.substringBefore('-').substringBefore('_').lowercase()
        return supported.any {
            it.substringBefore('-').substringBefore('_').lowercase() == wanted
        }
    }
}
