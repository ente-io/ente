import "package:photos/data/months.dart";
import 'package:tuple/tuple.dart';

class DateParseService {
  static final DateParseService instance =
      DateParseService._privateConstructor();
  DateParseService._privateConstructor();

  static const Map<String, int> _monthMap = {
    "january": 1,
    "february": 2,
    "march": 3,
    "april": 4,
    "may": 5,
    "june": 6,
    "july": 7,
    "august": 8,
    "september": 9,
    "october": 10,
    "november": 11,
    "december": 12,
    "jan": 1,
    "feb": 2,
    "mar": 3,
    "apr": 4,
    "jun": 6,
    "jul": 7,
    "aug": 8,
    "sep": 9,
    "sept": 9,
    "oct": 10,
    "nov": 11,
    "dec": 12,
    "janu": 1,
    "febr": 2,
    "marc": 3,
    "apri": 4,
    "juli": 7,
    "augu": 8,
    "sepe": 9,
    "octo": 10,
    "nove": 11,
    "dece": 12,
  };

  static const Map<int, String> monthNumberToName = {
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

  String normalizeDateString(String input) {
    return input
        .toLowerCase()
        .replaceAllMapped(
          RegExp(r'\b(\d{1,2})(st|nd|rd|th)\b'),
          (match) => match.group(1)!,
        )
        .replaceAll(RegExp(r'\bof\b'), '')
        .replaceAll(RegExp(r'[,\.]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Tuple3<int?, int?, int?> parseStructuredFormats(String input) {
    final normalized = input.replaceAll(RegExp(r'\s'), '');

    // ISO format: YYYY-MM-DD or YYYY/MM/DD
    final isoMatch =
        RegExp(r'^(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})$').firstMatch(normalized);
    if (isoMatch != null) {
      return Tuple3(
        int.tryParse(isoMatch.group(3)!), // day
        int.tryParse(isoMatch.group(2)!), // month
        int.tryParse(isoMatch.group(1)!), // year
      );
    }

    // Standard formats: MM/DD/YYYY, DD/MM/YYYY, MM-DD-YYYY, DD-MM-YYYY
    final standardMatch =
        RegExp(r'^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})$').firstMatch(normalized);
    if (standardMatch != null) {
      final first = int.tryParse(standardMatch.group(1)!);
      final second = int.tryParse(standardMatch.group(2)!);
      final year = int.tryParse(standardMatch.group(3)!);

      if (first == null || second == null || year == null) {
        return const Tuple3(null, null, null);
      }
      if (first < 1 || first > 31 || second < 1 || second > 31) {
        return const Tuple3(null, null, null);
      }

      // Heuristic: if first number > 12, assume DD/MM format
      if (first > 12) {
        if (second > 12) return const Tuple3(null, null, null);
        return Tuple3(first, second, year);
      } else {
        if (second > 12) return const Tuple3(null, null, null);
        return Tuple3(second, first, year);
      }
    }

    // Standard formats with 2-digit years: MM/DD/YY, DD/MM/YY, MM-DD-YY, DD-MM-YY
    final standardMatchTwoDigitYear =
        RegExp(r'^(\d{1,2})[\/-](\d{1,2})[\/-](\d{2})$').firstMatch(normalized);
    if (standardMatchTwoDigitYear != null) {
      final first = int.tryParse(standardMatchTwoDigitYear.group(1)!);
      final second = int.tryParse(standardMatchTwoDigitYear.group(2)!);
      final yearTwoDigit = int.tryParse(standardMatchTwoDigitYear.group(3)!);

      if (first == null || second == null || yearTwoDigit == null) {
        return const Tuple3(null, null, null);
      }
      if (first < 1 || first > 31 || second < 1 || second > 31) {
        return const Tuple3(null, null, null);
      }

      final year =
          yearTwoDigit < 50 ? 2000 + yearTwoDigit : 1900 + yearTwoDigit;

      if (first > 12) {
        if (second > 12) return const Tuple3(null, null, null);
        return Tuple3(first, second, year);
      } else {
        if (second > 12) return const Tuple3(null, null, null);
        return Tuple3(second, first, year);
      }
    }

    // Dot format: DD.MM.YYYY
    final dotMatch =
        RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(normalized);
    if (dotMatch != null) {
      final day = int.tryParse(dotMatch.group(1)!);
      final month = int.tryParse(dotMatch.group(2)!);
      final year = int.tryParse(dotMatch.group(3)!);

      if (day == null || month == null || year == null) {
        return const Tuple3(null, null, null);
      }
      if (day < 1 || day > 31 || month < 1 || month > 12) {
        return const Tuple3(null, null, null);
      }

      return Tuple3(day, month, year);
    }

    // Dot format with 2-digit year: DD.MM.YY
    final dotMatchTwoDigitYear =
        RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{2})$').firstMatch(normalized);
    if (dotMatchTwoDigitYear != null) {
      final day = int.tryParse(dotMatchTwoDigitYear.group(1)!);
      final month = int.tryParse(dotMatchTwoDigitYear.group(2)!);
      final yearTwoDigit = int.tryParse(dotMatchTwoDigitYear.group(3)!);

      if (day == null || month == null || yearTwoDigit == null) {
        return const Tuple3(null, null, null);
      }
      if (day < 1 || day > 31 || month < 1 || month > 12) {
        return const Tuple3(null, null, null);
      }

      final year =
          yearTwoDigit < 50 ? 2000 + yearTwoDigit : 1900 + yearTwoDigit;

      return Tuple3(day, month, year);
    }

    // Compact format: YYYYMMDD
    if (normalized.length == 8 && RegExp(r'^\d{8}$').hasMatch(normalized)) {
      final year = int.tryParse(normalized.substring(0, 4));
      final month = int.tryParse(normalized.substring(4, 6));
      final day = int.tryParse(normalized.substring(6, 8));
      if (year != null &&
          year > 1900 &&
          month != null &&
          month <= 12 &&
          day != null &&
          day <= 31) {
        return Tuple3(day, month, year);
      }
    }

    // Short format: MM/DD or DD/MM
    final shortMatch =
        RegExp(r'^(\d{1,2})[\/-](\d{1,2})$').firstMatch(normalized);
    if (shortMatch != null) {
      final first = int.tryParse(shortMatch.group(1)!);
      final second = int.tryParse(shortMatch.group(2)!);

      if (first == null || second == null) {
        return const Tuple3(null, null, null);
      }
      if (first < 1 || first > 31 || second < 1 || second > 31) {
        return const Tuple3(null, null, null);
      }

      if (first > 12) {
        if (second > 12) return const Tuple3(null, null, null);
        return Tuple3(first, second, null);
      } else {
        if (second > 12) return const Tuple3(null, null, null);
        return Tuple3(second, first, null);
      }
    }

    return const Tuple3(null, null, null);
  }

  Tuple3<int?, MonthData?, int?> _parseDateParts(String input) {
    if (input.trim().isEmpty) return const Tuple3(null, null, null);

    final lowerInput = input.toLowerCase();
    final today = DateTime.now();

    if (lowerInput.contains('today')) {
      return Tuple3(
        today.day,
        MonthData(monthNumberToName[today.month]!, today.month),
        today.year,
      );
    } else if (lowerInput.contains('tomorrow')) {
      final tomorrow = today.add(const Duration(days: 1));
      return Tuple3(
        tomorrow.day,
        MonthData(monthNumberToName[tomorrow.month]!, tomorrow.month),
        tomorrow.year,
      );
    } else if (lowerInput.contains('yesterday')) {
      final yesterday = today.subtract(const Duration(days: 1));
      return Tuple3(
        yesterday.day,
        MonthData(monthNumberToName[yesterday.month]!, yesterday.month),
        yesterday.year,
      );
    }

    // Check for year-only queries like "2025"
    final yearOnlyMatch = RegExp(r'^\s*(\d{4})\s*$').firstMatch(input.trim());
    if (yearOnlyMatch != null) {
      final year = int.tryParse(yearOnlyMatch.group(1)!);
      if (year != null && year >= 1900 && year <= 2100) {
        return Tuple3(null, null, year);
      }
    }

    // First try structured formats (slash, dash, dot patterns)
    final structuredResult = parseStructuredFormats(input);
    if (structuredResult.item1 != null ||
        structuredResult.item2 != null ||
        structuredResult.item3 != null) {
      final int? day = structuredResult.item1;
      final int? monthNum = structuredResult.item2;
      final int? year = structuredResult.item3;
      MonthData? monthData;
      if (monthNum != null && monthNumberToName.containsKey(monthNum)) {
        monthData = MonthData(monthNumberToName[monthNum]!, monthNum);
      }
      return Tuple3(day, monthData, year);
    }

    final normalized = normalizeDateString(input);
    final tokens = normalized.split(RegExp(r'\s+'));

    int? day, monthNum, year;
    MonthData? monthData;

    // Handle patterns like "25 02" (day month) or "Feb 2025" (month year)
    if (tokens.length == 2) {
      final first = tokens[0];
      final second = tokens[1];

      // Check if first token is a month name and second is a year
      if (_monthMap.containsKey(first)) {
        final yearValue = int.tryParse(second);
        if (yearValue != null && yearValue >= 1900 && yearValue <= 2100) {
          monthNum = _monthMap[first];
          year = yearValue;
        }
      }
      // Check if both are numbers - could be day+month or month+day
      else {
        final firstNum = int.tryParse(first);
        final secondNum = int.tryParse(second);

        if (firstNum != null && secondNum != null) {
          if (secondNum >= 1900 && secondNum <= 2100) {
            if (firstNum >= 1 && firstNum <= 12) {
              monthNum = firstNum;
              year = secondNum;
            }
          } else if (firstNum >= 1 &&
              firstNum <= 31 &&
              secondNum >= 1 &&
              secondNum <= 12) {
            day = firstNum;
            monthNum = secondNum;
          } else if (firstNum >= 1 &&
              firstNum <= 12 &&
              secondNum >= 1 &&
              secondNum <= 31) {
            monthNum = firstNum;
            day = secondNum;
          }
        }
      }
    }

    if (day == null && monthNum == null && year == null) {
      for (var token in tokens) {
        if (_monthMap.containsKey(token)) {
          monthNum = _monthMap[token];
        } else if (RegExp(r'^\d+$').hasMatch(token)) {
          final value = int.parse(token);
          if (value >= 1900 && value <= 2100) {
            year = value;
          } else if (value >= 1 && value <= 31) {
            if (day == null) {
              day = value;
            } else if (monthNum == null && value <= 12) {
              monthNum = value;
            }
          } else if (value >= 32 && value <= 99) {
            year = value < 50 ? 2000 + value : 1900 + value;
          }
        }
      }
    }

    if (monthNum != null && monthNumberToName.containsKey(monthNum)) {
      monthData = MonthData(monthNumberToName[monthNum]!, monthNum);
    }

    if (monthNum != null && (monthNum < 1 || monthNum > 12)) {
      monthNum = null;
      monthData = null;
    }
    if (day != null && (day < 1 || day > 31)) {
      day = null;
    }

    return Tuple3(day, monthData, year);
  }

  Tuple3<int?, MonthData?, int?> parseDate(String input) {
    return _parseDateParts(input);
  }

  List<Tuple3<int?, MonthData?, int?>> parseDateVariations(String input) {
    final List<Tuple3<int?, MonthData?, int?>> variations = [];
    final primaryResult = _parseDateParts(input);

    variations.add(primaryResult);
    return variations;
  }

  bool isYearQuery(String input) {
    final yearOnlyMatch = RegExp(r'^\s*(\d{4})\s*$').firstMatch(input.trim());
    if (yearOnlyMatch != null) {
      final year = int.tryParse(yearOnlyMatch.group(1)!);
      return year != null && year >= 1900 && year <= 2100;
    }
    return false;
  }

  bool isGenericDateQuery(String input) {
    final result = _parseDateParts(input);
    return result.item1 != null && result.item2 != null && result.item3 == null;
  }
}
