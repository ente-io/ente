// Common runtime exceptions that can occur during normal app operation.
// These are recoverable conditions that should be caught and handled.

/// Marker for expected runtime conditions that are handled locally.
///
/// These may still be written to local logs, but should not be reported as app
/// crashes.
abstract interface class LocallyHandledError {}

class WidgetUnmountedException implements Exception {
  final String? message;

  WidgetUnmountedException([this.message]);

  @override
  String toString() => message != null
      ? 'WidgetUnmountedException: $message'
      : 'WidgetUnmountedException';
}
