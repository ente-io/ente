import "package:intl/intl.dart";
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
    int? firstCreationTime,
    int? lastCreationTime,
  }) : super(
          memories,
          MemoryType.time,
          '',
          firstDateToShow,
          lastDateToShow,
        );

  @override
  String createTitle() {
    if (day != null) {
      final dayFormat = DateFormat.MMMd().format(day!);
      if (yearsAgo != null) {
        return "$dayFormat, ${yearsAgo!} years ago";
      } else {
        return "$dayFormat through the years";
      }
    }
    if (month != null) {
      final monthFormat = DateFormat.MMMM().format(month!);
      if (yearsAgo != null) {
        return "$monthFormat, ${yearsAgo!} years ago";
      } else {
        return "$monthFormat through the years";
      }
    }
    if (yearsAgo != null) {
      return "This week, ${yearsAgo!} years ago";
    } else {
      return "This week through the years";
    }
  }
}
