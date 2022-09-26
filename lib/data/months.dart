List<MonthData> allMonths = [
  MonthData('January', 1),
  MonthData('February', 2),
  MonthData('March', 3),
  MonthData('April', 4),
  MonthData('May', 5),
  MonthData('June', 6),
  MonthData('July', 7),
  MonthData('August', 8),
  MonthData('September', 9),
  MonthData('October', 10),
  MonthData('November', 11),
  MonthData('December', 12),
];

class MonthData {
  final String name;
  final int monthNumber;

  MonthData(this.name, this.monthNumber);
}
