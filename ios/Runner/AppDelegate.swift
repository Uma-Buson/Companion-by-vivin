import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var blurEffectView: UIVisualEffectView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Observe screen recording changes to protect sensitive content
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    checkScreenCapture()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Obscure app content in the iOS app switcher / multitasking view
  override func applicationWillResignActive(_ application: UIApplication) {
    applyPrivacyBlur()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    removePrivacyBlur()
    checkScreenCapture()
  }

  @objc private func screenCaptureChanged() {
    checkScreenCapture()
  }

  private func checkScreenCapture() {
    if #available(iOS 11.0, *) {
      if UIScreen.main.isCaptured {
        applyPrivacyBlur()
      } else {
        removePrivacyBlur()
      }
    }
  }

  private func applyPrivacyBlur() {
    guard blurEffectView == nil, let window = self.window else { return }
    let blurEffect = UIBlurEffect(style: .extraLight)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.frame = window.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    blurView.tag = 9999
    window.addSubview(blurView)
    blurEffectView = blurView
  }

  private func removePrivacyBlur() {
    blurEffectView?.removeFromSuperview()
    blurEffectView = nil
    self.window?.viewWithTag(9999)?.removeFromSuperview()
  }
}
