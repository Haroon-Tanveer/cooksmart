# Flutter's own rules are contributed by the Gradle plugin; these cover the
# plugins this app uses. R8 runs on release builds only.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
-keep class androidx.lifecycle.DefaultLifecycleObserver

# http is used by the Groq proxy client and its image downloads.
-keep class io.flutter.plugins.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
