import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var pencilMethodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      pencilMethodChannel = FlutterMethodChannel(
        name: "com.aisip.ono/pencil_events",
        binaryMessenger: controller.binaryMessenger
      )

      let pencilInteraction = UIPencilInteraction()
      pencilInteraction.delegate = self
      controller.view.addInteraction(pencilInteraction)
    }

    return result
  }
}

extension AppDelegate: UIPencilInteractionDelegate {
  func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
    pencilMethodChannel?.invokeMethod("doubleTap", arguments: nil)
  }
}