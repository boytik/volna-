import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Канал для одного вопроса: умеет ли этот телефон распознавать речь
  /// на устройстве для нужной локали.
  ///
  /// Плагин `speech_to_text` такого ответа не даёт — он просто падает
  /// с ошибкой уже во время записи. Нам же ответ нужен ДО того, как
  /// человек заговорит: от него зависит, что написано на экране про
  /// приватность. Обещание нельзя уточнять задним числом.
  private static let channelName = "io.volna.volna/speech"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Мост неявного движка не отдаёт messenger напрямую — берём его
    // через регистратор, как это делают плагины.
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "VolnaSpeechChannel"
    ) else { return }

    let channel = FlutterMethodChannel(
      name: AppDelegate.channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "supportsOnDevice":
        let args = call.arguments as? [String: Any]
        let localeId = (args?["locale"] as? String) ?? "ru-RU"
        result(AppDelegate.supportsOnDevice(localeId: localeId))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// `supportsOnDeviceRecognition` истинно только когда для этой локали
  /// на телефоне скачан пакет диктовки. Для русского это обычно значит
  /// включённую русскую диктовку в настройках клавиатуры — то есть у
  /// нашей аудитории почти всегда, но проверять всё равно надо.
  private static func supportsOnDevice(localeId: String) -> Bool {
    let locale = Locale(identifier: localeId)
    guard let recognizer = SFSpeechRecognizer(locale: locale) else { return false }
    guard recognizer.isAvailable else { return false }
    if #available(iOS 13.0, *) {
      return recognizer.supportsOnDeviceRecognition
    }
    return false
  }
}
