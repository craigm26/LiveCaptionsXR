# Flutter framework specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# MediaPipe comprehensive rules
-keep class com.google.mediapipe.** { *; }
-keepnames class com.google.mediapipe.** { *; }
-keep class com.google.mediapipe.proto.** { *; }
-keepnames class com.google.mediapipe.proto.** { *; }
-keep class com.google.mediapipe.tasks.** { *; }
-keepnames class com.google.mediapipe.tasks.** { *; }
-keep class com.google.mediapipe.framework.** { *; }
-keepnames class com.google.mediapipe.framework.** { *; }

# Protobuf comprehensive rules
-keep class com.google.protobuf.** { *; }
-keepnames class com.google.protobuf.** { *; }
-keep class com.google.protobuf.Internal.** { *; }
-keepnames class com.google.protobuf.Internal.** { *; }

# Missing classes from R8 analysis - add these to suppress warnings
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate
-dontwarn com.google.protobuf.Internal$ProtoMethodMayReturnNull
-dontwarn com.google.protobuf.Internal$ProtoNonnullApi
-dontwarn com.google.protobuf.ProtoField
-dontwarn com.google.protobuf.ProtoPresenceBits
-dontwarn com.google.protobuf.ProtoPresenceCheckedField

# OkHttp rules
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# AutoValue rules
-keep class com.google.auto.value.** { *; }
-keep @com.google.auto.value.AutoValue class *

# BouncyCastle rules
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Conscrypt rules
-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**

# OpenJSSE rules
-keep class org.openjsse.** { *; }
-dontwarn org.openjsse.**

# JTransforms rules
-keep class com.github.wendykierp.JTransforms.** { *; }
-dontwarn com.github.wendykierp.JTransforms.**

# Google Android rules
-keep class com.google.android.** { *; }
-dontwarn com.google.android.**

# Javax Lang Model rules
-keep class javax.lang.model.** { *; }
-dontwarn javax.lang.model.**

# Javax Tools rules
-keep class javax.tools.** { *; }
-dontwarn javax.tools.**

# Additional rules for AR and ML libraries
-keep class com.google.ar.** { *; }
-keepnames class com.google.ar.** { *; }
-dontwarn com.google.ar.**

# ML Kit rules
-keep class com.google.mlkit.** { *; }
-keepnames class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# CameraX rules
-keep class androidx.camera.** { *; }
-keepnames class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Guava rules
-keep class com.google.common.** { *; }
-keepnames class com.google.common.** { *; }
-dontwarn com.google.common.**

# Flutter packages specific rules
# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }
-keepnames class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }
-keepnames class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Flutter sound
-keep class com.bluefire.beam.** { *; }
-keepnames class com.bluefire.beam.** { *; }
-dontwarn com.bluefire.beam.**

# Device info plus
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-keepnames class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.device_info.**

# Google sign in
-keep class com.google.android.gms.** { *; }
-keepnames class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# YouTube player iframe
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keepnames class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# Audio streamer
-keep class com.example.audio_streamer.** { *; }
-keepnames class com.example.audio_streamer.** { *; }
-dontwarn com.example.audio_streamer.**

# Whisper GGML
-keep class com.whisper.** { *; }
-keepnames class com.whisper.** { *; }
-dontwarn com.whisper.**

# Flutter Gemma
-keep class com.flutter.gemma.** { *; }
-keepnames class com.flutter.gemma.** { *; }
-dontwarn com.flutter.gemma.**

# General rules for reflection and serialization
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
