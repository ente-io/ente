-keep class ai.onnxruntime.** { *; }
# To ensure that stack traces is unambiguous
# https://developer.android.com/studio/build/shrink-code#decode-stack-trace
-keepattributes LineNumberTable,SourceFile

-keep class org.chromium.net.** { *; }
-keep class org.xmlpull.v1.** { *; }