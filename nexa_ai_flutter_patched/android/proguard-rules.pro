# Gson uses generic type information stored in a class file when working with fields.
# R8 removes generic signature information by default.

# Keep Gson TypeToken and its generic signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep generic signature of TypeToken
-keepattributes Signature

# Keep classes used for JSON serialization/deserialization
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Nexa AI SDK rules
-keep class ai.nexa.** { *; }
-keepclassmembers class ai.nexa.** { *; }
-keep class com.nexa.sdk.** { *; }
-keepclassmembers class com.nexa.sdk.** { *; }

# Keep the plugin classes
-keep class com.example.nexa_ai_flutter.** { *; }
