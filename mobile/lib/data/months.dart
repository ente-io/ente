import "package:flutter/widgets.dart";
import "package:intl/intl.dart";

final Map<String, List<MonthData>> _cache = {};

List<MonthData> getMonthData(BuildContext context) {
  final locale = Localizations.localeOf(context).toString();

  if (!_cache.containsKey(locale)) {
    final dateSymbols = DateFormat('MMMM', locale).dateSymbols;
    _cache[locale] = List.generate(
      12,
      (index) => MonthData(dateSymbols.MONTHS[index], index + 1),
    );
  }
  return _cache[locale]!;
}

class MonthData {
  final String name;
  final int monthNumber;

  MonthData(this.name, this.monthNumber);
}
