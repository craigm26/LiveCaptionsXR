import SceneKit
import UIKit

@available(iOS 14.0, *)
class SpatialCaptionNode: SCNNode {
    private let textNode: SCNNode
    private let backgroundNode: SCNNode

    init(text: String, fontSize: CGFloat = 0.08, bubbleWidth: CGFloat = 0.25) {
        self.textNode = SCNNode()
        self.backgroundNode = SCNNode() // Keep for compatibility but don't use
        super.init()

        // Create the text geometry with normal size
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        
        // Make sure text is WHITE and visible
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.1) // Add slight glow
        textGeometry.firstMaterial?.specular.contents = UIColor.white
        textGeometry.firstMaterial?.isDoubleSided = true
        textGeometry.flatness = 0.1
        
        print("🎨 [CaptionNode] Setting text color to WHITE with glow")
        
        textNode.geometry = textGeometry
        let nodeScale = SCNVector3(x: 0.2, y: 0.2, z: 0.2) // Even bigger readable size (4x original)
        textNode.scale = nodeScale
        
        // Simple text positioning - center the text geometry
        let (min, max) = textGeometry.boundingBox
        let textWidth = CGFloat((max.x - min.x) * 0.2) // Account for scale 0.2
        let textHeight = CGFloat((max.y - min.y) * 0.2)
        
        // Center text by moving it left and down by half its size
        textNode.position = SCNVector3(
            x: Float(-textWidth / 2),
            y: Float(-textHeight / 2), 
            z: 0
        )
        
        print("🎯 [CaptionNode] Text centered at: (\(Float(-textWidth / 2)), \(Float(-textHeight / 2)), 0)")
        print("📏 [CaptionNode] Text size: \(textWidth) x \(textHeight)")

        // NO BACKGROUND - just add the text node
        addChildNode(textNode)
        
        print("🏗️ [CaptionNode] Added ONLY text node (no background)")

        // Re-enable billboard constraint for text to face camera
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .Y
        constraints = [billboardConstraint]

        // Fade-in animation
        opacity = 0.0
        let fadeIn = SCNAction.fadeIn(duration: 0.3)
        runAction(fadeIn)
        
        print("📝 [CaptionNode] Created caption with text: \"\(text)\", scale: 0.2 (4x bigger), NO BACKGROUND")
        print("🎨 [CaptionNode] Text should be WHITE")
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