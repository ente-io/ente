import "package:flutter/cupertino.dart";
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

Map<int, String> _months = {
  1: "Jan",
  2: "Feb",
  3: "Mar",
  4: "Apr",
  5: "May",
  6: "Jun",
  7: "Jul",
  8: "Aug",
  9: "Sep",
  10: "Oct",
  11: "Nov",
  12: "Dec",
};

final currentYear = DateTime.now().year;
const searchStartYear = 1970;

bool areFromSameDay(int firstCreationTime, int secondCreationTime) {
  final firstDate = DateTime.fromMicrosecondsSinceEpoch(firstCreationTime);
  final secondDate = DateTime.fromMicrosecondsSinceEpoch(secondCreationTime);
  return firstDate.year == secondDate.year &&
      firstDate.month == secondDate.month &&
      firstDate.day == secondDate.day;
}

bool areDatesInSameWeek(DateTime date1, DateTime date2) {
  if (date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day) {
    return true;
  }
  final int dayOfWeek1 = date1.weekday;
  final int dayOfWeek2 = date2.weekday;
  // Calculate the start and end dates of the week for both dates
  final DateTime startOfWeek1 = date1.subtract(Duration(days: dayOfWeek1 - 1));
  final DateTime endOfWeek1 = startOfWeek1.add(const Duration(days: 6));
  final DateTime startOfWeek2 = date2.subtract(Duration(days: dayOfWeek2 - 1));
  final DateTime endOfWeek2 = startOfWeek2.add(const Duration(days: 6));
  // Check if the two dates fall within the same week range
  if ((date1.isAfter(startOfWeek2) && date1.isBefore(endOfWeek2)) ||
      (date2.isAfter(startOfWeek1) && date2.isBefore(endOfWeek1))) {
    return true;
  }
  return false;
}

// Create link default names:
// Same day: "Dec 19, 2022"
// Same month: "Dec 19 - 22, 2022"
// Base case: "Dec 19, 2022 - Jan 7, 2023"
String getNameForDateRange(int firstCreationTime, int secondCreationTime) {
  final startTime = DateTime.fromMicrosecondsSinceEpoch(firstCreationTime);
  final endTime = DateTime.fromMicrosecondsSinceEpoch(secondCreationTime);
  // different year
  if (startTime.year != endTime.year) {
    return "${_months[startTime.month]!} ${startTime.day}, ${startTime.year} - "
        "${_months[endTime.month]!} ${endTime.day}, ${endTime.year}";
  }
  // same year, diff month
  if (startTime.month != endTime.month) {
    return "${_months[startTime.month]!} ${startTime.day} - "
        "${_months[endTime.month]!} ${endTime.day}, ${endTime.year}";
  }
  // same month and year, diff day
  if (startTime.day != endTime.day) {
    return "${_months[startTime.month]!} ${startTime.day} - "
        "${_months[endTime.month]!} ${endTime.day}, ${endTime.year}";
  }
  // same day
  return "${_months[endTime.month]!} ${endTime.day}, ${endTime.year}";
}

//11:22 AM
String getTimeIn12hrFormat(DateTime dateTime) {
  return DateFormat.jm().format(dateTime);
}

//Thu, Jun 30, 2022 - 14:32
String getFormattedTime(BuildContext context, DateTime dateTime) {
  return DateFormat(
    'E, MMM d, y - HH:mm',
    Localizations.localeOf(context).languageCode,
  ).format(
    dateTime,
  );
}

String formatDuration(Duration position) {
  final ms = position.inMilliseconds;

  int seconds = ms ~/ 1000;
  final int hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  final minutes = seconds ~/ 60;
  seconds = seconds % 60;

  final hoursString = hours >= 10
      ? '$hours'
      : hours == 0
          ? '00'
          : '0$hours';

  final minutesString = minutes >= 10
      ? '$minutes'
      : minutes == 0
          ? '00'
          : '0$minutes';

  final secondsString = seconds >= 10
      ? '$seconds'
      : seconds == 0
          ? '00'
          : '0$seconds';

  final formattedTime =
      '${hoursString == '00' ? '' : hoursString + ':'}$minutesString:$secondsString';

  return formattedTime;
}

String secondsToHHMMSS(int value) {
  int h, m, s;
  h = value ~/ 3600;
  m = ((value - h * 3600)) ~/ 60;
  s = value - (h * 3600) - (m * 60);
  final String hourLeft =
      h.toString().length < 2 ? "0" + h.toString() : h.toString();

  final String minuteLeft =
      m.toString().length < 2 ? "0" + m.toString() : m.toString();

  final String secondsLeft =
      s.toString().length < 2 ? "0" + s.toString() : s.toString();

  final String result = "$hourLeft:$minuteLeft:$secondsLeft";

  return result;
}

bool isValidGregorianDate({
  required int day,
  required int month,
  required int year,
}) {
  if (day <= 0 || day > 31 || month <= 0 || month > 12 || year < 0) {
    return false;
  }
  if ((month == 4 || month == 6 || month == 9 || month == 11) && day > 30) {
    return false;
  }
  if (month == 2) {
    if (day > 29) {
      return false;
    }
    if (day == 29 && (year % 4 != 0 || (year % 100 == 0 && year % 400 != 0))) {
      return false;
    }
  }
  return true;
}

final RegExp exp = RegExp('[\\.A-Za-z]*');

DateTime? parseDateTimeFromFileNameV2(
  String fileName, {
  /* to avoid parsing incorrect date time from the filename, the max and min
    year limits the chances of parsing incorrect date times
    */
  int minYear = 1990,
  int? maxYear,
}) {
  // add next year to avoid corner cases for 31st Dec
  maxYear ??= currentYear + 1;
  String val = fileName.replaceAll(exp, '');
  if (val.isNotEmpty && !isNumeric(val[0])) {
    val = val.substring(1, val.length);
  }
  if (val.isNotEmpty && !isNumeric(val[val.length - 1])) {
    val = val.substring(0, val.length - 1);
  }
  final int countOfHyphen = val.split("-").length - 1;
  final int countUnderScore = val.split("_").length - 1;
  String valForParser = val;
  if (countOfHyphen == 1) {
    valForParser = val.replaceAll("-", "T");
  } else if (countUnderScore == 1 || countUnderScore == 2) {
    valForParser = val.replaceFirst("_", "T");
    if (countUnderScore == 2) {
      valForParser = valForParser.split("_")[0];
    }
  } else if (countOfHyphen == 2) {
    valForParser = val.replaceAll(".", ":");
  } else if (countOfHyphen == 6 || countOfHyphen == 7) {
    final splits = val.split("-");
    valForParser =
        "${splits[0]}${splits[1]}${splits[2]}T${splits[3]}${splits[4]}${splits[5]}";
  }
  final result = DateTime.tryParse(valForParser);
  if (kDebugMode && result == null) {
    debugPrint("Failed to parse $fileName dateTime from $valForParser");
  }
  if (result != null && result.year >= minYear && result.year <= maxYear) {
    return result;
  }
  return null;
}

bool isNumeric(String? s) {
  if (s == null) {
    return false;
  }
  return double.tryParse(s) != null;
}

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

/// Returns the duration in the format "h:mm:ss" or "m:ss".
String secondsToDuration(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  } else {
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
