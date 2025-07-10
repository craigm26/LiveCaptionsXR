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

        // Create the text geometry
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.firstMaterial?.isDoubleSided = true
        textNode.geometry = textGeometry
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        let (min, max) = textGeometry.boundingBox
        textNode.position = SCNVector3(-((max.x - min.x) / 2), min.y, 0.01)

        // Create the background geometry
        let width = max.x - min.x
        let height = max.y - min.y
        let backgroundGeometry = SCNPlane(width: bubbleWidth, height: fontSize * 1.5)
        backgroundGeometry.cornerRadius = fontSize * 0.4
        backgroundGeometry.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.7)
        backgroundNode.geometry = backgroundGeometry
        backgroundNode.position = SCNVector3(0, 0, 0)

        // Add the nodes to the hierarchy
        addChildNode(backgroundNode)
        addChildNode(textNode)

        // Add a billboard constraint
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .Y
        constraints = [billboardConstraint]

        // Fade-in animation
        opacity = 0.0
        let fadeIn = SCNAction.fadeIn(duration: 0.3)
        runAction(fadeIn)
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
