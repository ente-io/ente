# Keep error_prone annotations
-dontwarn com.google.errorprone.annotations.**
-dontnote com.google.errorprone.annotations.**

# Keep all annotations
-keepattributes *Annotation*

# Keep Tink crypto library classes
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Keep Sodium crypto library classes
-keep class com.goterl.lazysodium.** { *; }
-dontwarn com.goterl.lazysodium.**

# Keep Ente crypto classes
-keep class io.ente.** { *; }
-dontwarn io.ente.**
