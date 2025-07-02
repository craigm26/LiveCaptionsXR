import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Basic Flutter app delegate - AR and visual features temporarily disabled
        // TODO: Re-enable AR features once Swift compilation issues are resolved
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
