# ============================================================
# ProGuard Rules — E-Ticketing Helpdesk
# Modul 7 Praktikum Mobile
# ============================================================

# Flutter embedding / plugins
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase / Google Play Services
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.messaging.** { *; }

# Supabase / Networking
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-dontwarn kotlinx.serialization.**
-dontwarn com.google.android.play.core.tasks.**

# Gson / reflection
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Kotlin metadata / coroutines warnings
-dontwarn kotlin.**
-dontwarn kotlinx.**

# Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Serializable names
-keepnames class * implements java.io.Serializable

# R class members
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep annotations and inner class metadata
-keepattributes EnclosingMethod
-keepattributes InnerClasses
