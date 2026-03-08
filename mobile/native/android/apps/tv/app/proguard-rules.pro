# Add project specific ProGuard rules here.

# JNA uses reflection for native bindings.
-keep class com.sun.jna.** { *; }
-dontwarn com.sun.jna.**

# UniFFI bindings rely on JNA mapping method names to native symbols.
-keep class io.ente.photos.screensaver.ente.uniffi.** { *; }
