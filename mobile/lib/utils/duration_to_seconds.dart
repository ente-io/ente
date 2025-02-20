/// Returns the duration in seconds from the format "h:mm:ss" or "m:ss".
int? durationToSeconds(String? duration) {
  if (duration == null) {
    return null;
  }
  final parts = duration.split(':');
  int seconds = 0;

  if (parts.length == 3) {
    // Format: "h:mm:ss"
    seconds += int.parse(parts[0]) * 3600; // Hours to seconds
    seconds += int.parse(parts[1]) * 60; // Minutes to seconds
    seconds += int.parse(parts[2]); // Seconds
  } else if (parts.length == 2) {
    // Format: "m:ss"
    seconds += int.parse(parts[0]) * 60; // Minutes to seconds
    seconds += int.parse(parts[1]); // Seconds
  } else {
    throw FormatException('Invalid duration format: $duration');
  }

  return seconds;
}
