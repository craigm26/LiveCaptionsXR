package com.livecaptionsxr.app

import android.os.SystemClock
import kotlin.math.max

class HybridLocalizationEngine {
    // State: [x, y, z, vx, vy, vz]
    private val state = DoubleArray(6) { 0.0 }
    private val covariance = Array(6) { DoubleArray(6) { if (it == it) 1.0 else 0.0 } }
    private val processNoise = 0.01
    private val measurementNoiseAudio = 0.2
    private val measurementNoiseVision = 0.05
    private var lastUpdate: Long = SystemClock.elapsedRealtime()

    // Prediction step (constant velocity)
    fun predict() {
        val now = SystemClock.elapsedRealtime()
        val dt = max((now - lastUpdate) / 1000.0, 1e-3)
        lastUpdate = now
        val F = transitionMatrix(dt)
        val newState = DoubleArray(6)
        for (i in 0..5) {
            for (j in 0..5) {
                newState[i] += F[i][j] * state[j]
            }
        }
        for (i in 0..5) state[i] = newState[i]
        val Ft = transpose(F)
        val temp = matMul(F, covariance)
        val newCov = matAdd(matMul(temp, Ft), scalarMat(processNoise, 6))
        for (i in 0..5) for (j in 0..5) covariance[i][j] = newCov[i][j]
    }

    // Update with audio (angle, confidence, deviceTransform)
    fun updateWithAudioMeasurement(angle: Float, confidence: Float, deviceTransform: FloatArray) {
        // deviceTransform: 16 floats, column-major 4x4
        val distance = 2.0f
        val y = Math.sin(angle.toDouble()).toFloat()
        val x = Math.cos(angle.toDouble()).toFloat()
        val local = floatArrayOf(x * distance, 0f, y * distance, 1f)
        val world = mat4x4MulVec4(deviceTransform, local)
        val measurement = doubleArrayOf(world[0].toDouble(), world[1].toDouble(), world[2].toDouble())
        kalmanUpdate(measurement, measurementNoiseAudio / confidence.toDouble())
    }

    // Update with vision (3D transform, confidence)
    fun updateWithVisualMeasurement(transform: FloatArray, confidence: Float) {
        val measurement = doubleArrayOf(transform[12].toDouble(), transform[13].toDouble(), transform[14].toDouble())
        kalmanUpdate(measurement, measurementNoiseVision / confidence.toDouble())
    }

    // Kalman update step (position only)
    private fun kalmanUpdate(measurement: DoubleArray, noise: Double) {
        // H: 3x6
        val H = arrayOf(
            doubleArrayOf(1.0,0.0,0.0,0.0,0.0,0.0),
            doubleArrayOf(0.0,1.0,0.0,0.0,0.0,0.0),
            doubleArrayOf(0.0,0.0,1.0,0.0,0.0,0.0)
        )
        val R = arrayOf(
            doubleArrayOf(noise,0.0,0.0),
            doubleArrayOf(0.0,noise,0.0),
            doubleArrayOf(0.0,0.0,noise)
        )
        val Ht = transpose(H)
        val y = DoubleArray(3) { measurement[it] - (0..5).sumOf { j -> H[it][j] * state[j] } }
        val S = matAdd(matMul(matMul(H, covariance), Ht), R)
        val S_inv = invert3x3(S)
        val K = matMul(matMul(covariance, Ht), S_inv)
        for (i in 0..5) state[i] += (0..2).sumOf { j -> K[i][j] * y[j] }
        val KH = matMul(K, H)
        val I = identity(6)
        val temp = matSub(I, KH)
        val newCov = matMul(temp, covariance)
        for (i in 0..5) for (j in 0..5) covariance[i][j] = newCov[i][j]
    }

    // Output: fused world transform for AR anchor (column-major 4x4)
    val fusedTransform: FloatArray
        get() {
            val t = FloatArray(16) { 0f }
            t[0] = 1f; t[5] = 1f; t[10] = 1f; t[15] = 1f
            t[12] = state[0].toFloat()
            t[13] = state[1].toFloat()
            t[14] = state[2].toFloat()
            return t
        }

    // Helpers
    private fun transitionMatrix(dt: Double): Array<DoubleArray> {
        val F = identity(6)
        F[0][3] = dt; F[1][4] = dt; F[2][5] = dt
        return F
    }
    private fun identity(n: Int) = Array(n) { i -> DoubleArray(n) { j -> if (i == j) 1.0 else 0.0 } }
    private fun scalarMat(s: Double, n: Int) = Array(n) { DoubleArray(n) { if (it == it) s else 0.0 } }
    private fun matAdd(a: Array<DoubleArray>, b: Array<DoubleArray>) = Array(a.size) { i -> DoubleArray(a[0].size) { j -> a[i][j] + b[i][j] } }
    private fun matSub(a: Array<DoubleArray>, b: Array<DoubleArray>) = Array(a.size) { i -> DoubleArray(a[0].size) { j -> a[i][j] - b[i][j] } }
    private fun matMul(a: Array<DoubleArray>, b: Array<DoubleArray>): Array<DoubleArray> {
        val res = Array(a.size) { DoubleArray(b[0].size) }
        for (i in a.indices) for (j in b[0].indices) for (k in b.indices) res[i][j] += a[i][k] * b[k][j]
        return res
    }
    private fun matMul(a: Array<DoubleArray>, b: DoubleArray): DoubleArray {
        val res = DoubleArray(a.size)
        for (i in a.indices) for (j in b.indices) res[i] += a[i][j] * b[j]
        return res
    }
    private fun transpose(a: Array<DoubleArray>): Array<DoubleArray> {
        val res = Array(a[0].size) { DoubleArray(a.size) }
        for (i in a.indices) for (j in a[0].indices) res[j][i] = a[i][j]
        return res
    }
    private fun invert3x3(m: Array<DoubleArray>): Array<DoubleArray> {
        val a = m[0][0]; val b = m[0][1]; val c = m[0][2]
        val d = m[1][0]; val e = m[1][1]; val f = m[1][2]
        val g = m[2][0]; val h = m[2][1]; val i = m[2][2]
        val det = a*e*i + b*f*g + c*d*h - c*e*g - b*d*i - a*f*h
        val inv = Array(3) { DoubleArray(3) }
        inv[0][0] = (e*i - f*h)/det; inv[0][1] = (c*h - b*i)/det; inv[0][2] = (b*f - c*e)/det
        inv[1][0] = (f*g - d*i)/det; inv[1][1] = (a*i - c*g)/det; inv[1][2] = (c*d - a*f)/det
        inv[2][0] = (d*h - e*g)/det; inv[2][1] = (b*g - a*h)/det; inv[2][2] = (a*e - b*d)/det
        return inv
    }
    private fun mat4x4MulVec4(m: FloatArray, v: FloatArray): FloatArray {
        val res = FloatArray(4)
        for (i in 0..3) res[i] = m[i]*v[0] + m[4+i]*v[1] + m[8+i]*v[2] + m[12+i]*v[3]
        return res
    }
} 