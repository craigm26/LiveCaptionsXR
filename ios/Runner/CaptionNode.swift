import SceneKit
import UIKit

@available(iOS 14.0, *)
class CaptionNode: SCNNode {
    private let textNode: SCNNode
    private let backgroundNode: SCNNode

    init(text: String, fontSize: CGFloat = 0.08, bubbleWidth: CGFloat = 0.25) {
        self.textNode = SCNNode()
        self.backgroundNode = SCNNode()
        super.init()

        // Create the text geometry with normal size
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.firstMaterial?.isDoubleSided = true
        textGeometry.flatness = 0.1
        
        textNode.geometry = textGeometry
        let nodeScale = SCNVector3(x: 0.1, y: 0.1, z: 0.1) // HUGE scale for visibility
        textNode.scale = nodeScale
        
        // Center the text
        let (min, max) = textGeometry.boundingBox
        let textWidth = CGFloat((max.x - min.x) * 0.1) // Account for HUGE scale
        let textHeight = CGFloat((max.y - min.y) * 0.1)
        textNode.position = SCNVector3(x: Float(-textWidth / 2), y: Float(-textHeight / 2), z: 0.01)

        // Create the background geometry
        let padding: CGFloat = 0.02
        let backgroundWidth = Swift.max(bubbleWidth, textWidth + padding * 2)
        let backgroundHeight = textHeight + padding * 2
        
        let backgroundGeometry = SCNPlane(width: backgroundWidth, height: backgroundHeight)
        backgroundGeometry.cornerRadius = backgroundHeight * 0.3
        backgroundGeometry.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.8) // BRIGHT YELLOW background
        backgroundGeometry.firstMaterial?.isDoubleSided = true
        backgroundNode.geometry = backgroundGeometry
        backgroundNode.position = SCNVector3(x: 0, y: 0, z: 0)

        // Add the nodes to the hierarchy
        addChildNode(backgroundNode)
        addChildNode(textNode)

        // Add a billboard constraint to always face camera
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .Y
        constraints = [billboardConstraint]

        // Fade-in animation
        opacity = 0.0
        let fadeIn = SCNAction.fadeIn(duration: 0.3)
        runAction(fadeIn)
        
        print("📝 [CaptionNode] Created caption with text: \"\(text)\", scale: 0.01, background: \(backgroundWidth)x\(backgroundHeight)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fadeOutAndRemove(after delay: TimeInterval = 4.0) {
        let wait = SCNAction.wait(duration: delay)
        let fadeOut = SCNAction.fadeOut(duration: 0.3)
        let remove = SCNAction.removeFromParentNode()
        let sequence = SCNAction.sequence([wait, fadeOut, remove])
        runAction(sequence)
    }
}
