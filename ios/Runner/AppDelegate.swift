import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var visualSpeakerIdentifier: VisualSpeakerIdentifier?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not type FlutterViewController")
        }

        let visualChannel = FlutterMethodChannel(name: "com.craig.livecaptions/visual",
                                                 binaryMessenger: controller.binaryMessenger)
        
        if #available(iOS 14.0, *) {
            self.visualSpeakerIdentifier = VisualSpeakerIdentifier(channel: visualChannel)
        }

        visualChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            if #available(iOS 14.0, *) {
                switch call.method {
                case "startDetection":
                    self.visualSpeakerIdentifier?.startDetection()
                    result(nil)
                case "stopDetection":
                    self.visualSpeakerIdentifier?.stopDetection()
                    result(nil)
                // Example of how audio service would notify vision service
                case "setSpeechDetected":
                    if let isDetected = call.arguments as? Bool {
                        self.visualSpeakerIdentifier?.setSpeechDetected(isDetected)
                    }
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
