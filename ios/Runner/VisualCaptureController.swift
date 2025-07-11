import Foundation
import Flutter

@available(iOS 14.0, *)
class VisualCaptureController {
    private let visualSpeakerIdentifier: VisualSpeakerIdentifier

    init(channel: FlutterMethodChannel) {
        self.visualSpeakerIdentifier = VisualSpeakerIdentifier(channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "captureVisualSnapshot":
            Task {
                let snapshot = await visualSpeakerIdentifier.captureFrame()
                result(snapshot)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
