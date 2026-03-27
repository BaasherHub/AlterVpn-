# ──────────────────────────────────────────────────────────
# ProGuard / R8 rules for AlterVPN release builds
# ──────────────────────────────────────────────────────────

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# OpenVPN Flutter plugin
-keep class de.blinkt.openvpn.** { *; }
-keep class net.openvpn.** { *; }

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**
