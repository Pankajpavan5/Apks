# ProGuard rules for the combined Rezuku build.
#
# Most of the obfuscation here is about keeping reflective access (Shizuku,
# HiddenApiBypass, Compose runtime) working after R8 has stripped names.

# Keep the Shizuku binder plumbing intact — the rikka.shizuku.* classes do
# AIDL-style reflection.
-keep class rikka.shizuku.** { *; }
-keep class rikka.sui.** { *; }
-keep class dev.rikka.shizuku.** { *; }

# HiddenApiBypass touches reflection on hidden framework APIs.
-keep class org.lsposed.hiddenapibypass.** { *; }

# Compose runtime keeps a lot of state in lambdas and stabilises generated
# classes; the default R8 rules cover most of this but we keep the obvious
# entry points.
-keep class androidx.compose.runtime.** { *; }
-keep class com.rezuku.pk.** { *; }

# Keep the application class so the OS can instantiate it by name.
-keep public class com.rezuku.pk.RezukuApplication { *; }

# Kotlin metadata + serialization
-keep class kotlin.Metadata { *; }
-keepclassmembers class * {
    @kotlinx.serialization.Serializable <fields>;
}

# Silence warnings about missing classes that are only present on certain
# Android API levels (e.g. newer NetworkCapabilities constants).
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
