import Foundation
import Flutter
import ARKit
import UIKit

class VisualObjectPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "live_captions_xr/visual_object_methods", binaryMessenger: registrar.messenger())
        VisualObjectPlugin.channel = channel
        let instance = VisualObjectPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // Example: Call this when you detect an ARAnchor or object
    static func sendVisualObjectDetected(anchor: ARAnchor, label: String, confidence: Double, boundingBox: [Double]) {
        let tf = anchor.transform
        let arr: [Double] = [
            Double(tf.columns.0.x), Double(tf.columns.0.y), Double(tf.columns.0.z), Double(tf.columns.0.w),
            Double(tf.columns.1.x), Double(tf.columns.1.y), Double(tf.columns.1.z), Double(tf.columns.1.w),
            Double(tf.columns.2.x), Double(tf.columns.2.y), Double(tf.columns.2.z), Double(tf.columns.2.w),
            Double(tf.columns.3.x), Double(tf.columns.3.y), Double(tf.columns.3.z), Double(tf.columns.3.w)
        ]
        let args: [String: Any] = [
            "label": label,
            "confidence": confidence,
            "boundingBox": boundingBox, // [left, top, right, bottom]
            "worldTransform": arr
        ]
        channel?.invokeMethod("onVisualObjectDetected", arguments: args)
    }

    // No-op: Dart->native calls not needed for this plugin
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterMethodNotImplemented)
    }
} 