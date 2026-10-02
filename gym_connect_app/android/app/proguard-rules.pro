# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit Pose Detection Rules
-keep class com.google.mlkit.** { *; }
-keepclassmembers class * { @com.google.mlkit.** <methods>; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Android Security & Crypto for FlutterSecureStorage
-keep class androidx.security.crypto.** { *; }

# Supabase, OkHttp, WebSockets
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**

# Health Connect & AndroidX
-keep class androidx.health.** { *; }

# Google Play Core & Flutter Deferred Components
-dontwarn com.google.android.play.core.**

