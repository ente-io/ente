-keep class ai.onnxruntime.** { *; }
# To ensure that stack traces is unambiguous
# https://developer.android.com/studio/build/shrink-code#decode-stack-trace
-keepattributes LineNumberTable,SourceFile

-keep class org.chromium.net.** { *; }

# App was failing without these
# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn androidx.window.extensions.WindowExtensions
-dontwarn androidx.window.extensions.WindowExtensionsProvider
-dontwarn androidx.window.extensions.area.ExtensionWindowAreaPresentation
-dontwarn androidx.window.extensions.layout.DisplayFeature
-dontwarn androidx.window.extensions.layout.FoldingFeature
-dontwarn androidx.window.extensions.layout.WindowLayoutComponent
-dontwarn androidx.window.extensions.layout.WindowLayoutInfo
-dontwarn androidx.window.sidecar.SidecarDeviceState
-dontwarn androidx.window.sidecar.SidecarDisplayFeature
-dontwarn androidx.window.sidecar.SidecarInterface$SidecarCallback
-dontwarn androidx.window.sidecar.SidecarInterface
-dontwarn androidx.window.sidecar.SidecarProvider
-dontwarn androidx.window.sidecar.SidecarWindowLayoutInfo
-dontwarn androidx.compose.ui.Modifier
-dontwarn androidx.compose.ui.layout.LayoutCoordinates
-dontwarn androidx.compose.ui.layout.LayoutCoordinatesKt
-dontwarn androidx.compose.ui.layout.ModifierInfo
-dontwarn androidx.compose.ui.node.LayoutNode
-dontwarn androidx.compose.ui.node.NodeCoordinator
-dontwarn androidx.compose.ui.node.Owner
-dontwarn androidx.compose.ui.semantics.AccessibilityAction
-dontwarn androidx.compose.ui.semantics.SemanticsActions
-dontwarn androidx.compose.ui.semantics.SemanticsConfiguration
-dontwarn androidx.compose.ui.semantics.SemanticsConfigurationKt
-dontwarn androidx.compose.ui.semantics.SemanticsProperties
-dontwarn androidx.compose.ui.semantics.SemanticsPropertyKey
-dontwarn androidx.compose.ui.text.TextLayoutInput
-dontwarn androidx.compose.ui.text.TextLayoutResult
-dontwarn androidx.compose.ui.text.TextStyle