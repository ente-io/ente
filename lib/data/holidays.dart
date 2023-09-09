import "package:flutter/cupertino.dart";

class HolidayData {
  final String name;
  final int month;
  final int day;

  HolidayData(this.name, {required this.month, required this.day});
}

// Based on the locale, this return holidays that have fixed date as per the
// Gregorian calendar. For example, Christmas is always on December 25th.
List<HolidayData> getHolidays(BuildContext context) {
  final locale = Localizations.localeOf(context);
  if (localeToHolidays.containsKey(locale.toLanguageTag())) {
    return localeToHolidays[locale.toLanguageTag()]!;
  } else if (localeToHolidays.containsKey(locale.languageCode)) {
    return localeToHolidays[locale.languageCode]!;
  }
  return _defaultHolidays;
}

List<HolidayData> _defaultHolidays = [
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
  HolidayData('Halloween', month: 10, day: 31),
  HolidayData('Christmas Eve', month: 12, day: 24),
  HolidayData('Christmas', month: 12, day: 25),
  HolidayData('Boxing Day', month: 12, day: 26),
  HolidayData('New Year\'s Eve', month: 12, day: 31),
];
Map<String, List<HolidayData>> localeToHolidays = {
  'it': [
    HolidayData('Capodanno', month: 1, day: 1),
    // New Year's Day
    HolidayData('Epifania', month: 1, day: 6),
    // Epiphany
    HolidayData('San Valentino', month: 2, day: 14),
    // Valentine's Day
    HolidayData('Festa della Liberazione', month: 4, day: 25),
    // Liberation Day
    HolidayData('Primo Maggio', month: 5, day: 1),
    // Labor Day
    HolidayData('Festa della Repubblica', month: 6, day: 2),
    // Republic Day
    HolidayData('Ferragosto', month: 8, day: 15),
    // Assumption of Mary
    HolidayData('Halloween', month: 10, day: 31),
    // Halloween
    HolidayData('Ognissanti', month: 11, day: 1),
    // All Saints' Day
    HolidayData('Immacolata Concezione', month: 12, day: 8),
    // Immaculate Conception
    HolidayData('Natale', month: 12, day: 25),
    // Christmas Day
    HolidayData('Vigilia di Capodanno', month: 12, day: 31),
    // New Year's Eve
  ],
  'fr': [
    HolidayData('Jour de l\'An', month: 1, day: 1), // New Year's Day
    HolidayData('Fête du Travail', month: 5, day: 1), // Labour Day
    HolidayData('Fête Nationale', month: 7, day: 14), // Bastille Day
    HolidayData('Assomption', month: 8, day: 15), // Assumption of Mary
    HolidayData('Halloween', month: 10, day: 31), // Halloween
    HolidayData('Toussaint', month: 11, day: 1), // All Saints' Day
    HolidayData('Jour de l\'Armistice', month: 11, day: 11), // Armistice Day
    HolidayData('Noël', month: 12, day: 25), // Christmas
    HolidayData('Lendemain de Noël', month: 12, day: 26), // Boxing Day
    HolidayData('Saint-Sylvestre', month: 12, day: 31), // New Year's Eve
  ],
  'de': [
    HolidayData('Neujahrstag', month: 1, day: 1),
    // New Year
    HolidayData('Valentinstag', month: 2, day: 14),
    // Valentine's Day
    HolidayData('Tag der Arbeit', month: 5, day: 1),
    // Labor Day
    HolidayData('Tag der Deutschen Einheit', month: 10, day: 3),
    // German Unity Day
    HolidayData('Halloween', month: 10, day: 31),
    // Halloween
    HolidayData('Erster Weihnachtstag', month: 12, day: 25),
    // First Christmas Day
    HolidayData('Zweiter Weihnachtstag', month: 12, day: 26),
    // Second Christmas Day (Boxing Day)
    HolidayData('Silvester', month: 12, day: 31),
    // New Year's Eve
  ],
  'nl': [
    HolidayData('Nieuwjaarsdag', month: 1, day: 1), // New Year's Day
    HolidayData('Valentijnsdag', month: 2, day: 14), // Valentine's Day
    HolidayData('Koningsdag', month: 4, day: 27), // King's Day
    HolidayData('Bevrijdingsdag', month: 5, day: 5), // Liberation Day
    HolidayData('Halloween', month: 10, day: 31), // Halloween
    HolidayData('Sinterklaas', month: 12, day: 5), // Sinterklaas
    HolidayData('Eerste Kerstdag', month: 12, day: 25), // First Christmas Day
    HolidayData('Tweede Kerstdag', month: 12, day: 26), // Second Christmas Day
    HolidayData('Oudejaarsdag', month: 12, day: 31), // New Year's Eve
  ],
  'es': [
    HolidayData('Año Nuevo', month: 1, day: 1),
    // New Year's Day
    HolidayData('San Valentín', month: 2, day: 14),
    // Valentine's Day
    HolidayData('Día del Trabajador', month: 5, day: 1),
    // Labor Day
    HolidayData('Día de la Hispanidad', month: 10, day: 12),
    // Hispanic Day
    HolidayData('Halloween', month: 10, day: 31),
    // Halloween
    HolidayData('Día de Todos los Santos', month: 11, day: 1),
    // All Saints' Day
    HolidayData('Día de la Constitución', month: 12, day: 6),
    // Constitution Day
    HolidayData('La Inmaculada Concepción', month: 12, day: 8),
    // Immaculate Conception
    HolidayData('Navidad', month: 12, day: 25),
    // Christmas Day
    HolidayData('Nochevieja', month: 12, day: 31),
    // New Year's Eve
  ],
};
