// Common runtime exceptions that can occur during normal app operation.
// These are recoverable conditions that should be caught and handled.

class WidgetUnmountedException implements Exception {
  final String? message;

  WidgetUnmountedException([this.message]);

  @override
  String toString() => message != null
      ? 'WidgetUnmountedException: $message'
      : 'WidgetUnmountedException';
}
