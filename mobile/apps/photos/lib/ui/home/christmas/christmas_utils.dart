/// Returns true if the current date is within the Christmas period (Dec 24-26).
bool isChristmasPeriod() {
  final now = DateTime.now();
  return now.month == 12 && now.day >= 24 && now.day <= 26;
}
