Map<int, String> _months = {
  1: "Jan",
  2: "Feb",
  3: "March",
  4: "April",
  5: "May",
  6: "Jun",
  7: "July",
  8: "Aug",
  9: "Sep",
  10: "Oct",
  11: "Nov",
  12: "Dec",
};

Map<int, String> _fullMonths = {
  1: "January",
  2: "February",
  3: "March",
  4: "April",
  5: "May",
  6: "June",
  7: "July",
  8: "August",
  9: "September",
  10: "October",
  11: "November",
  12: "December",
};

Map<int, String> _days = {
  1: "Mon",
  2: "Tue",
  3: "Wed",
  4: "Thu",
  5: "Fri",
  6: "Sat",
  7: "Sun",
};

String getMonthAndYear(DateTime dateTime) {
  return _months[dateTime.month] + " " + dateTime.year.toString();
}

String getDayAndMonth(DateTime dateTime) {
  return _days[dateTime.weekday] +
      ", " +
      dateTime.day.toString() +
      " " +
      _months[dateTime.month];
}

String getDateAndMonthAndYear(DateTime dateTime) {
  return dateTime.day.toString() +
      " " +
      _months[dateTime.month] +
      ", " +
      dateTime.year.toString();
}

String getDay(DateTime dateTime) {
  return _days[dateTime.weekday];
}

String getMonth(DateTime dateTime) {
  return _months[dateTime.month];
}

String getFullMonth(DateTime dateTime) {
  return _fullMonths[dateTime.month];
}

String getTime(DateTime dateTime) {
  final hours = dateTime.hour > 9
      ? dateTime.hour.toString()
      : "0" + dateTime.hour.toString();
  final minutes = dateTime.minute > 9
      ? dateTime.minute.toString()
      : "0" + dateTime.minute.toString();
  return hours + ":" + minutes;
}

String getFormattedTime(DateTime dateTime) {
  return getDay(dateTime) +
      ", " +
      getMonth(dateTime) +
      " " +
      dateTime.day.toString() +
      ", " +
      dateTime.year.toString() +
      " - " +
      getTime(dateTime);
}

String getFormattedDate(DateTime dateTime) {
  return getDay(dateTime) +
      ", " +
      getMonth(dateTime) +
      " " +
      dateTime.day.toString() +
      ", " +
      dateTime.year.toString();
}

String formatDuration(Duration position) {
  final ms = position.inMilliseconds;

  int seconds = ms ~/ 1000;
  final int hours = seconds ~/ 3600;
  seconds = seconds % 3600;
  var minutes = seconds ~/ 60;
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

bool isLeapYear(DateTime dateTime) {
  final year = dateTime.year;
  if (year % 4 == 0) {
    if (year % 100 == 0) {
      if (year % 400 == 0) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  } else {
    return false;
  }
}
