import "package:intl/intl.dart";

/// Formats a timestamp (in microseconds) to a relative time string.
///
/// Server timestamps are in microseconds since epoch.
String formatRelativeTime(int timestampMicros) {
  final now = DateTime.now();
  final dateTime = DateTime.fromMicrosecondsSinceEpoch(timestampMicros);
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return "just now";
  } else if (difference.inMinutes < 60) {
    return "${difference.inMinutes}m ago";
  } else if (difference.inHours < 24) {
    return "${difference.inHours}hr ago";
  } else if (difference.inDays < 7) {
    return "${difference.inDays}d ago";
  } else {
    final sameYear = dateTime.year == now.year;
    return DateFormat(sameYear ? "MMM d" : "MMM d, yyyy").format(dateTime);
  }
}
