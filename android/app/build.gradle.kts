plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.live_captions_xr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.live_captions_xr"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Add externalNativeBuild arguments for 16 KB page size
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_PAGE_SIZE=16384")
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
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

    // Sceneform (optional, if used)
    // implementation("com.gorisse.thomas.sceneform:sceneform:1.21.0")
}

flutter {
    source = "../.."
}
