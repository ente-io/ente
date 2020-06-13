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
      _months[dateTime.month] +
      " " +
      dateTime.day.toString();
}

String getDay(DateTime dateTime) {
  return _days[dateTime.weekday];
}

String getMonth(DateTime dateTime) {
  return _months[dateTime.month];
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
