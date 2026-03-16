# android/app/proguard-rules.pro
# Ludo Tournament App - ProGuard / R8 rules

# ── Flutter ───────────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Hive ─────────────────────────────────────────────────────────────────────
-keep class com.hivedb.** { *; }
-keepclassmembers class * {
    @com.hivedb.HiveField *;
    @com.hivedb.HiveType *;
}

# ── WebSocket (Shelf / dart:io) ───────────────────────────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# ── Google Fonts ──────────────────────────────────────────────────────────────
-keep class com.google.android.gms.** { *; }

# ── QR Flutter ────────────────────────────────────────────────────────────────
-keep class com.github.zxing.** { *; }

# ── Keep model classes ────────────────────────────────────────────────────────
-keep class com.ssitnexus.ludo_tournament_app.** { *; }

# ── Supabase / Realtime ───────────────────────────────────────────────────────
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
# OkHttp (used by supabase_flutter WebSocket)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ── AudioPlayers ──────────────────────────────────────────────────────────────
-keep class xyz.luan.audioplayers.** { *; }

# ── General ───────────────────────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
