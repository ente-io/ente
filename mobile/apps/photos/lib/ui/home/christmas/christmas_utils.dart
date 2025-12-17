import "package:photos/service_locator.dart";

/// Returns true if the current date is within the Christmas period (Dec 24-26).
bool isChristmasDateRange() {
  final now = DateTime.now();
  return now.month == 12 && now.day >= 24 && now.day <= 26;
}

/// Returns true if the current date is within the Christmas period (Dec 24-26)
/// and the Christmas banner setting is enabled.
bool isChristmasPeriod() {
  if (!localSettings.isChristmasBannerEnabled) {
    return false;
  }
  return isChristmasDateRange();
}
