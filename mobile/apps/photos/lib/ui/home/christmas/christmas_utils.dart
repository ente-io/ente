import "package:photos/service_locator.dart";

/// Returns true if the current date is within the Christmas period (Dec 24-26)
/// and the Easter animation setting is enabled.
bool isChristmasPeriod() {
  if (!localSettings.isEasterAnimationEnabled) {
    return false;
  }
  final now = DateTime.now();
  return now.month == 12 && now.day >= 24 && now.day <= 26;
}
