class HolidayData {
  final String name;
  final int month;
  final int day;

  const HolidayData(this.name, {required this.month, required this.day});
}

const List<HolidayData> allHolidays = [
  HolidayData('New Year', month: 1, day: 1),
  HolidayData('Epiphany', month: 1, day: 6),
  HolidayData('Pongal', month: 1, day: 14),
  HolidayData('Makar Sankranthi', month: 1, day: 14),
  HolidayData('Valentine\'s Day', month: 2, day: 14),
  HolidayData('Nowruz', month: 3, day: 21),
  HolidayData('Walpurgis Night', month: 4, day: 30),
  HolidayData('Vappu', month: 4, day: 30),
  HolidayData('May Day', month: 5, day: 1),
  HolidayData('Midsummer\'s Eve', month: 6, day: 24),
  HolidayData('Midsummer Day', month: 6, day: 25),
  HolidayData('Christmas Eve', month: 12, day: 24),
  HolidayData('Halloween', month: 10, day: 31),
  HolidayData('Christmas', month: 12, day: 25),
  HolidayData('Boxing Day', month: 12, day: 26),
  HolidayData('New Year\'s Eve', month: 12, day: 31),
];
