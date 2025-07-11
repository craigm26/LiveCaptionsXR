# Flutter framework specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.google.mediapipe.** { *; }
-keep class com.google.protobuf.** { *; }
-keepnames class com.google.mediapipe.** { *; }
-keepnames class com.google.protobuf.** { *; }

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
