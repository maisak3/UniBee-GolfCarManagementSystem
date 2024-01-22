import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    GMSServices.provideAPIKey("AIzaSyCjbqcHhZ6o9Hw9ptILhuj22y5nVIA-zsc")

        if #available(iOS 10.0, *) {
     UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
