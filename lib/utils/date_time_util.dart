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
