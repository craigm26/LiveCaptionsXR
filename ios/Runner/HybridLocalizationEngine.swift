import Foundation
import simd
import Accelerate

// 6x6 identity matrix helper
typealias simd_double6 = SIMD6<Double>
typealias simd_double6x6 = simd_double6x6_t
let matrix_identity_double6x6 = simd_double6x6(diagonal: simd_double6(repeating: 1.0))

class HybridLocalizationEngine {
    // State: [x, y, z, vx, vy, vz]
    private var state = simd_double6(repeating: 0)
    private var covariance = matrix_identity_double6x6
    private let processNoise: Double = 0.01
    private let measurementNoiseAudio: Double = 0.2
    private let measurementNoiseVision: Double = 0.05
    private var lastUpdate: Date = Date()

    // Prediction step (constant velocity)
    func predict() {
        let dt = Date().timeIntervalSince(lastUpdate)
        lastUpdate = Date()
        let F = HybridLocalizationEngine.transitionMatrix(dt: dt)
        state = F * state
        covariance = F * covariance * F.transpose + processNoise * matrix_identity_double6x6
    }

    // Update with audio (angle, confidence, deviceTransform)
    func updateWithAudioMeasurement(angle: Float, confidence: Float, deviceTransform: simd_float4x4) {
        // Convert angle to a 3D point in world space using deviceTransform
        let distance: Float = 2.0 // Assume default distance
        let yRotation = simd_float4x4(SCNMatrix4MakeRotation(angle, 0, 1, 0))
        let translation = simd_float4x4(SCNMatrix4MakeTranslation(0, 0, -distance))
        let worldTransform = deviceTransform * yRotation * translation
        let measurement = simd_double3(Double(worldTransform.columns.3.x), Double(worldTransform.columns.3.y), Double(worldTransform.columns.3.z))
        kalmanUpdate(measurement: measurement, noise: measurementNoiseAudio / Double(confidence))
    }

    // Update with vision (3D transform, confidence)
    func updateWithVisualMeasurement(transform: simd_float4x4, confidence: Float) {
        let measurement = simd_double3(Double(transform.columns.3.x), Double(transform.columns.3.y), Double(transform.columns.3.z))
        kalmanUpdate(measurement: measurement, noise: measurementNoiseVision / Double(confidence))
    }

    // Kalman update step (position only)
    private func kalmanUpdate(measurement: simd_double3, noise: Double) {
        // Measurement matrix H (extracts position)
        var H = simd_double3x6(rows: [
            simd_double6(1,0,0,0,0,0),
            simd_double6(0,1,0,0,0,0),
            simd_double6(0,0,1,0,0,0)
        ])
        let R = simd_double3x3(diagonal: simd_double3(repeating: noise))
        let y = measurement - H * state
        let S = H * covariance * H.transpose + R
        let K = covariance * H.transpose * S.inverse
        state = state + K * y
        covariance = (matrix_identity_double6x6 - K * H) * covariance
    }

    // Output: fused world transform for AR anchor
    var fusedTransform: simd_float4x4 {
        var t = matrix_identity_float4x4
        t.columns.3 = simd_float4(Float(state[0]), Float(state[1]), Float(state[2]), 1)
        return t
    }

    // Helper: transition matrix for constant velocity
    static func transitionMatrix(dt: Double) -> simd_double6x6 {
        var F = matrix_identity_double6x6
        F[0,3] = dt; F[1,4] = dt; F[2,5] = dt
        return F
    }
} 