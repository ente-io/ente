/// Webp only support android.
///
/// heic:
/// - iOS: support iOS11+.
/// - android: API 28+, and May require hardware encoder support, does not guarantee that all devices above API28 are available. Use [HeifWriter](https://developer.android.com/reference/androidx/heifwriter/HeifWriter.html)
enum CompressFormat { jpeg, png, heic, webp }
