import "package:intl/intl.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/memories/memory.dart";
import "package:photos/models/memories/smart_memory.dart";

class TimeMemory extends SmartMemory {
  // For computing the title
  DateTime? day;
  DateTime? month;
  int? yearsAgo;

  TimeMemory(
    List<Memory> memories,
    int firstDateToShow,
    int lastDateToShow, {
    this.day,
    this.month,
    this.yearsAgo,
    super.firstCreationTime,
    super.lastCreationTime,
  }) : super(
          memories,
          MemoryType.time,
          '',
          firstDateToShow,
          lastDateToShow,
        );

  @override
  String createTitle(S s, String languageCode) {
    if (day != null) {
      final dayFormat = DateFormat.MMMd(languageCode).format(day!);
      if (yearsAgo != null) {
        return "$dayFormat, " + s.yearsAgo(yearsAgo!);
      } else {
        return s.throughTheYears(dayFormat);
      }
    }
    if (month != null) {
      final monthFormat = DateFormat.MMMM(languageCode).format(month!);
      if (yearsAgo != null) {
        return "$monthFormat, " + s.yearsAgo(yearsAgo!);
      } else {
        return s.throughTheYears(monthFormat);
      }
    }
    if (yearsAgo != null) {
      return s.thisWeekXYearsAgo(yearsAgo!);
    } else {
      return s.thisWeekThroughTheYears;
    }
  }
}
