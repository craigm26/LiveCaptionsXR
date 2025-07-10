import Foundation
import Flutter
import Accelerate

@objc class SpeechLocalizerPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "live_captions_xr/speech_localizer", binaryMessenger: registrar.messenger())
        let instance = SpeechLocalizerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "estimateDirection":
            guard let args = call.arguments as? [String: Any],
                  let left = args["left"] as? FlutterStandardTypedData,
                  let right = args["right"] as? FlutterStandardTypedData,
                  let sampleRate = args["sampleRate"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid arguments", details: nil))
                return
            }
            let micDistance = args["micDistance"] as? Double ?? 0.08
            let soundSpeed = args["soundSpeed"] as? Double ?? 343.0
            let angle = Self.estimateDirectionGccPhat(
                left: left.data,
                right: right.data,
                sampleRate: sampleRate,
                micDistance: micDistance,
                soundSpeed: soundSpeed
            )
            result(angle)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    static func estimateDirectionGccPhat(left: Data, right: Data, sampleRate: Double, micDistance: Double, soundSpeed: Double) -> Double {
        let n = min(left.count, right.count) / 4
        guard n > 0 else { return 0 }
        let N = 1 << (Int(log2(Double(n))) + 1)
        var leftFloats = [Float](repeating: 0, count: N)
        var rightFloats = [Float](repeating: 0, count: N)
        left.withUnsafeBytes { ptr in
            _ = memcpy(&leftFloats, ptr.baseAddress!, n * 4)
        }
        right.withUnsafeBytes { ptr in
            _ = memcpy(&rightFloats, ptr.baseAddress!, n * 4)
        }
        // Zero-pad
        for i in n..<N { leftFloats[i] = 0; rightFloats[i] = 0 }
        var splitLeft = DSPSplitComplex(realp: .allocate(capacity: N/2), imagp: .allocate(capacity: N/2))
        var splitRight = DSPSplitComplex(realp: .allocate(capacity: N/2), imagp: .allocate(capacity: N/2))
        let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Double(N))), FFTRadix(kFFTRadix2))
        leftFloats.withUnsafeBufferPointer { lPtr in
            rightFloats.withUnsafeBufferPointer { rPtr in
                vDSP_ctoz(UnsafePointer<DSPComplex>(OpaquePointer(lPtr.baseAddress!)), 2, &splitLeft, 1, vDSP_Length(N/2))
                vDSP_ctoz(UnsafePointer<DSPComplex>(OpaquePointer(rPtr.baseAddress!)), 2, &splitRight, 1, vDSP_Length(N/2))
                vDSP_fft_zrip(fftSetup!, &splitLeft, 1, vDSP_Length(log2(Double(N))), FFTDirection(FFT_FORWARD))
                vDSP_fft_zrip(fftSetup!, &splitRight, 1, vDSP_Length(log2(Double(N))), FFTDirection(FFT_FORWARD))
                // GCC-PHAT cross spectrum
                var crossReal = [Float](repeating: 0, count: N/2)
                var crossImag = [Float](repeating: 0, count: N/2)
                for i in 0..<N/2 {
                    let lr = splitLeft.realp[i] * splitRight.realp[i] + splitLeft.imagp[i] * splitRight.imagp[i]
                    let li = splitLeft.imagp[i] * splitRight.realp[i] - splitLeft.realp[i] * splitRight.imagp[i]
                    let mag = sqrt(lr * lr + li * li)
                    if mag > 1e-8 {
                        crossReal[i] = lr / mag
                        crossImag[i] = li / mag
                    }
                }
                var cross = DSPSplitComplex(realp: &crossReal, imagp: &crossImag)
                vDSP_fft_zrip(fftSetup!, &cross, 1, vDSP_Length(log2(Double(N))), FFTDirection(FFT_INVERSE))
                // Find max index (time delay)
                var corr = [Float](repeating: 0, count: N)
                corr.withUnsafeMutableBufferPointer { corrPtr in
                    corrPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: N/2) { complexPtr in
                        vDSP_ztoc(&cross, 1, complexPtr, 2, vDSP_Length(N/2))
                    }
                }
                var maxVal: Float = 0
                var maxIdx: vDSP_Length = 0
                vDSP_maxvi(corr, 1, &maxVal, &maxIdx, vDSP_Length(N))
                var delay = Int(maxIdx)
                if delay > N/2 { delay = delay - N }
                let timeDelay = Double(delay) / sampleRate
                let maxDelay = micDistance / soundSpeed
                let clamped = max(-1.0, min(timeDelay / maxDelay, 1.0))
                vDSP_destroy_fftsetup(fftSetup)
                splitLeft.realp.deallocate(); splitLeft.imagp.deallocate()
                splitRight.realp.deallocate(); splitRight.imagp.deallocate()
                return Double(asin(clamped))
            }
        }
        return 0
    }
} 