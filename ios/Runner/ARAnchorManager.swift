import ARKit
import SceneKit

@available(iOS 14.0, *)
class ARAnchorManager {
    private let session: ARSession
    private let sceneView: ARSCNView

    init(session: ARSession, sceneView: ARSCNView) {
        self.session = session
        self.sceneView = sceneView
    }

    func createAnchor(at angle: Float, distance: Float = 2.0, text: String) {
        guard let frame = session.currentFrame else { return }
        let cameraTransform = frame.camera.transform
        
        // Create a rotation matrix from the angle
        let rotation = simd_float4x4(SCNMatrix4MakeRotation(angle, 0, 1, 0))
        
        // Create a translation matrix from the distance
        let translation = simd_float4x4(SCNMatrix4MakeTranslation(0, 0, -distance))
        
        // Combine the transforms
        let transform = simd_mul(simd_mul(cameraTransform, translation), rotation)
        
        let anchor = ARAnchor(transform: transform)
        session.add(anchor: anchor)

        let captionNode = CaptionNode(text: text)
        sceneView.scene.rootNode.addChildNode(captionNode)
        captionNode.position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    func createAnchor(at worldTransform: simd_float4x4, text: String) {
        let anchor = ARAnchor(transform: worldTransform)
        session.add(anchor: anchor)

        let captionNode = CaptionNode(text: text)
        sceneView.scene.rootNode.addChildNode(captionNode)
        captionNode.position = SCNVector3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
    }

    func removeAnchor(_ anchor: ARAnchor) {
        session.remove(anchor: anchor)
        // TODO: Remove the corresponding CaptionNode from the scene
    }
}
