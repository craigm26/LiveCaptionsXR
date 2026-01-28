import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("app/key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.livecaptionsxr.app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    // Required for Nexa SDK native libraries
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // Updated Application ID for Google Play Store
        applicationId = "com.livecaptionsxr.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 27
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "upload"
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = file(keystoreProperties["storeFile"] as String? ?: "upload-keystore.jks")
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Additional R8 configuration to be more conservative
            proguardFile("proguard-rules.pro")
            
            // 16 KB page size support for release builds
            externalNativeBuild {
                cmake {
                    arguments += listOf("-DANDROID_PAGE_SIZE=16384")
                }
            }
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            
            // 16 KB page size support for debug builds
            externalNativeBuild {
                cmake {
                    arguments += listOf("-DANDROID_PAGE_SIZE=16384")
                }
            }
        }
    }
}

dependencies {
    // Nexa SDK for on-device AI inference (NPU/GPU/CPU)
    // Enables ASR, LLM, and VLM on Qualcomm Hexagon NPU
    implementation("ai.nexa:core:0.0.19")

    // CameraX
    implementation("androidx.camera:camera-core:1.3.1")
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")

    // ML Kit
    implementation("com.google.mlkit:face-detection:16.1.6")

    // JTransforms for FFT
    implementation("com.github.wendykierp:JTransforms:3.1")

    // ARCore
    implementation("com.google.ar:core:1.41.0")

    // Guava (for ListenableFuture, etc.)
    implementation("com.google.guava:guava:31.1-android")

    // Kotlin Coroutines for Nexa async operations
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Sceneform (optional, if used)
    // implementation("com.gorisse.thomas.sceneform:sceneform:1.21.0")
}

flutter {
    source = "../.."
}
