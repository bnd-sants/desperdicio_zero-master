import Flutter
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Configura o tratamento de notificações
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Método para lidar com a abertura de URLs personalizados
  override func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Notifica o Flutter sobre o deep link recebido
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.example.desperdicio_zero/deeplink", binaryMessenger: controller.binaryMessenger)
      channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
    }
    
    return true
  }
  
  // Método para lidar com Universal Links
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    // Verifica se é um Universal Link
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb, 
       let url = userActivity.webpageURL {
      // Notifica o Flutter sobre o Universal Link recebido
      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(name: "com.example.desperdicio_zero/deeplink", binaryMessenger: controller.binaryMessenger)
        channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
      }
    }
    
    return true
  }
}
