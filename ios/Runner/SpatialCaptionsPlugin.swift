import Flutter
import UIKit
import ARKit
import SceneKit

@available(iOS 14.0, *)
public class SpatialCaptionsPlugin: NSObject, FlutterPlugin {
    
    // Caption tracking
    private var captionNodes: [String: CaptionNodeWrapper] = [:]
    private var captionDuration: TimeInterval = 5.0
    
    // Scene reference
    weak var sceneView: ARSCNView?
    
    // Caption types
    enum CaptionType: String {
        case partial = "CaptionType.partial"
        case final = "CaptionType.final_"
        case enhanced = "CaptionType.enhanced"
    }
    
    // Caption node wrapper to track metadata
    class CaptionNodeWrapper {
        let node: SCNNode
        let captionNode: CaptionNode
        let type: CaptionType
        let speakerId: String?
        let timestamp: Date
        
        init(node: SCNNode, captionNode: CaptionNode, type: CaptionType, speakerId: String?) {
            self.node = node
            self.captionNode = captionNode
            self.type = type
            self.speakerId = speakerId
            self.timestamp = Date()
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "spatial_captions", binaryMessenger: registrar.messenger())
        let instance = SpatialCaptionsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "addCaption":
            handleAddCaption(call, result: result)
        case "updateCaption":
            handleUpdateCaption(call, result: result)
        case "replaceCaption":
            handleReplaceCaption(call, result: result)
        case "removeCaption":
            handleRemoveCaption(call, result: result)
        case "clearCaptions":
            handleClearCaptions(result: result)
        case "setCaptionDuration":
            handleSetCaptionDuration(call, result: result)
        case "setOrientationLock":
            handleSetOrientationLock(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Method Handlers
    
    private func handleAddCaption(_ call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let text = args["text"] as? String,
              let x = args["x"] as? Double,
              let y = args["y"] as? Double,
              let z = args["z"] as? Double,
              let typeString = args["type"] as? String,
              let type = CaptionType(rawValue: typeString),
              let sceneView = sceneView else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let speakerId = args["speakerId"] as? String
        let position = SCNVector3(Float(x), Float(y), Float(z))
        
        // Create caption node with appropriate styling based on type
        let captionNode = createStyledCaptionNode(text: text, type: type)
        
        // Create wrapper node for positioning
        let wrapperNode = SCNNode()
        wrapperNode.position = position
        wrapperNode.addChildNode(captionNode)
        
        // Add to scene
        sceneView.scene.rootNode.addChildNode(wrapperNode)
        
        // Track the caption
        captionNodes[id] = CaptionNodeWrapper(
            node: wrapperNode,
            captionNode: captionNode,
            type: type,
            speakerId: speakerId
        )
        
        // Animate entrance
        animateCaptionEntrance(captionNode)
        
        result(nil)
    }
    
    private func handleUpdateCaption(_ call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let wrapper = captionNodes[id] else {
            result(FlutterError(code: "NOT_FOUND", message: "Caption not found", details: nil))
            return
        }
        
        // Update text if provided
        if let text = args["text"] as? String {
            wrapper.captionNode.updateText(text)
        }
        
        // Update position if provided
        if let x = args["x"] as? Double,
           let y = args["y"] as? Double,
           let z = args["z"] as? Double {
            let newPosition = SCNVector3(Float(x), Float(y), Float(z))
            animateCaptionMove(wrapper.node, to: newPosition)
        }
        
        result(nil)
    }
    
    private func handleReplaceCaption(_ call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let oldId = args["oldId"] as? String,
              let newId = args["newId"] as? String,
              let text = args["text"] as? String,
              let typeString = args["type"] as? String,
              let type = CaptionType(rawValue: typeString),
              let oldWrapper = captionNodes[oldId] else {
            result(FlutterError(code: "NOT_FOUND", message: "Old caption not found", details: nil))
            return
        }
        
        // Get position and speaker from old caption
        let position = oldWrapper.node.position
        let speakerId = oldWrapper.speakerId
        
        // Create new caption at same position
        let newCaptionNode = createStyledCaptionNode(text: text, type: type)
        let newWrapperNode = SCNNode()
        newWrapperNode.position = position
        newWrapperNode.addChildNode(newCaptionNode)
        
        // Add new caption to scene
        sceneView?.scene.rootNode.addChildNode(newWrapperNode)
        
        // Track new caption
        captionNodes[newId] = CaptionNodeWrapper(
            node: newWrapperNode,
            captionNode: newCaptionNode,
            type: type,
            speakerId: speakerId
        )
        
        // Animate transition
        animateCaptionTransition(from: oldWrapper.captionNode, to: newCaptionNode) {
            // Remove old caption after transition
            oldWrapper.node.removeFromParentNode()
            self.captionNodes.removeValue(forKey: oldId)
        }
        
        result(nil)
    }
    
    private func handleRemoveCaption(_ call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String,
              let wrapper = captionNodes[id] else {
            result(FlutterError(code: "NOT_FOUND", message: "Caption not found", details: nil))
            return
        }
        
        // Animate exit
        animateCaptionExit(wrapper.captionNode) {
            wrapper.node.removeFromParentNode()
            self.captionNodes.removeValue(forKey: id)
        }
        
        result(nil)
    }
    
    private func handleClearCaptions(result: FlutterResult) {
        // Animate all captions out
        for (id, wrapper) in captionNodes {
            animateCaptionExit(wrapper.captionNode) {
                wrapper.node.removeFromParentNode()
            }
        }
        captionNodes.removeAll()
        result(nil)
    }
    
    private func handleSetCaptionDuration(_ call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let seconds = args["seconds"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid duration", details: nil))
            return
        }
        
        captionDuration = TimeInterval(seconds)
        result(nil)
    }
    
    private func handleSetOrientationLock(_ call: FlutterMethodCall, result: FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let lockLandscape = args["lockLandscape"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid orientation lock", details: nil))
            return
        }
        
        DispatchQueue.main.async {
            if lockLandscape {
                // Lock to landscape
                let value = UIInterfaceOrientation.landscapeRight.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
                
                // Set supported orientations
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appDelegate.orientationLock = .landscape
                }
            } else {
                // Unlock orientation
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    appDelegate.orientationLock = .all
                }
            }
        }
        
        result(nil)
    }
    
    // MARK: - Helper Methods
    
    private func createStyledCaptionNode(text: String, type: CaptionType) -> CaptionNode {
        // Customize appearance based on caption type
        let fontSize: CGFloat
        let backgroundColor: UIColor
        let textColor: UIColor
        let borderColor: UIColor
        
        switch type {
        case .partial:
            fontSize = 0.06
            backgroundColor = UIColor.black.withAlphaComponent(0.7)
            textColor = UIColor.white.withAlphaComponent(0.9)
            borderColor = UIColor.orange.withAlphaComponent(0.6)
        case .final:
            fontSize = 0.08
            backgroundColor = UIColor.black.withAlphaComponent(0.8)
            textColor = UIColor.white
            borderColor = UIColor.blue.withAlphaComponent(0.6)
        case .enhanced:
            fontSize = 0.08
            backgroundColor = UIColor.black.withAlphaComponent(0.85)
            textColor = UIColor.white
            borderColor = UIColor.green.withAlphaComponent(0.6)
        }
        
        let captionNode = CaptionNode(
            text: text,
            fontSize: fontSize,
            backgroundColor: backgroundColor,
            textColor: textColor,
            borderColor: borderColor
        )
        
        return captionNode
    }
    
    // MARK: - Animations
    
    private func animateCaptionEntrance(_ node: CaptionNode) {
        node.opacity = 0.0
        node.scale = SCNVector3(0.8, 0.8, 0.8)
        
        let fadeIn = SCNAction.fadeIn(duration: 0.3)
        let scaleUp = SCNAction.scale(to: 1.0, duration: 0.3)
        let group = SCNAction.group([fadeIn, scaleUp])
        
        node.runAction(group)
    }
    
    private func animateCaptionExit(_ node: CaptionNode, completion: @escaping () -> Void) {
        let fadeOut = SCNAction.fadeOut(duration: 0.3)
        let scaleDown = SCNAction.scale(to: 0.8, duration: 0.3)
        let group = SCNAction.group([fadeOut, scaleDown])
        
        node.runAction(group) {
            completion()
        }
    }
    
    private func animateCaptionMove(_ node: SCNNode, to position: SCNVector3) {
        let move = SCNAction.move(to: position, duration: 0.5)
        move.timingMode = .easeInEaseOut
        node.runAction(move)
    }
    
    private func animateCaptionTransition(from oldNode: CaptionNode, to newNode: CaptionNode, completion: @escaping () -> Void) {
        // Fade out old caption
        let fadeOut = SCNAction.fadeOut(duration: 0.2)
        
        // Scale and fade in new caption
        newNode.opacity = 0.0
        newNode.scale = SCNVector3(1.1, 1.1, 1.1)
        
        oldNode.runAction(fadeOut) {
            let fadeIn = SCNAction.fadeIn(duration: 0.3)
            let scaleNormal = SCNAction.scale(to: 1.0, duration: 0.3)
            let group = SCNAction.group([fadeIn, scaleNormal])
            
            newNode.runAction(group) {
                completion()
            }
        }
    }
}

// MARK: - Enhanced CaptionNode

@available(iOS 14.0, *)
extension CaptionNode {
    convenience init(text: String, 
                     fontSize: CGFloat,
                     backgroundColor: UIColor,
                     textColor: UIColor,
                     borderColor: UIColor) {
        self.init(text: text, fontSize: fontSize)
        
        // Update background color
        if let backgroundMaterial = self.childNodes.first?.geometry?.firstMaterial {
            backgroundMaterial.diffuse.contents = backgroundColor
        }
        
        // Update text color
        if let textGeometry = self.childNodes.last?.geometry as? SCNText {
            textGeometry.firstMaterial?.diffuse.contents = textColor
        }
        
        // Add border effect (using additional geometry or shader if needed)
        // This is a simplified version - you might want to enhance this
    }
    
    func updateText(_ newText: String) {
        if let textNode = self.childNodes.last,
           let textGeometry = textNode.geometry as? SCNText {
            textGeometry.string = newText
            
            // Update background size if needed
            let (min, max) = textGeometry.boundingBox
            let width = CGFloat(max.x - min.x) * 0.01 + 0.04
            let height = textGeometry.font.pointSize * 0.01 * 1.5
            
            if let backgroundNode = self.childNodes.first,
               let plane = backgroundNode.geometry as? SCNPlane {
                plane.width = width
                plane.height = height
            }
        }
    }
} 