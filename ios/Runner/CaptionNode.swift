import SceneKit

@available(iOS 14.0, *)
class CaptionNode: SCNNode {
    private let textNode: SCNNode
    private let backgroundNode: SCNNode

    init(text: String) {
        self.textNode = SCNNode()
        self.backgroundNode = SCNNode()
        super.init()

        // Create the text geometry
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: 0.1)
        textNode.geometry = textGeometry
        textNode.position = SCNVector3(-0.05, -0.05, 0.01)

        // Create the background geometry
        let (min, max) = textNode.boundingBox
        let width = max.x - min.x
        let height = max.y - min.y
        let backgroundGeometry = SCNPlane(width: CGFloat(width + 0.1), height: CGFloat(height + 0.1))
        backgroundGeometry.cornerRadius = 0.02
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
