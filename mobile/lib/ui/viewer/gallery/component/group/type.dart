import "package:flutter/widgets.dart";
import "package:intl/intl.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/utils/date_time_util.dart";

enum GroupType { day, week, month, size, year }

extension GroupTypeExtension on GroupType {
  String get name {
    switch (this) {
      case GroupType.day:
        return "day";
      case GroupType.week:
        return "week";
      case GroupType.month:
        return "month";
      case GroupType.size:
        return "size";
      case GroupType.year:
        return "year";
    }
  }

  String getTitle(BuildContext context, EnteFile file, {EnteFile? lastFile}) {
    if (this == GroupType.day) {
      return _getDayTitle(context, file.creationTime!);
    } else if (this == GroupType.week) {
      // return weeks starting date to end date based on file
      final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return "${DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(startOfWeek)} - ${DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(endOfWeek)}, ${endOfWeek.year}";
    } else if (this == GroupType.year) {
      final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      return DateFormat.y(Localizations.localeOf(context).languageCode)
          .format(date);
    } else {
      throw UnimplementedError("not implemented for $this");
    }
    throw UnimplementedError("not implemented for $this");
  }

  bool areFromSameGroup(EnteFile first, EnteFile second) {
    switch (this) {
      case GroupType.day:
        return areFromSameDay(first.creationTime!, second.creationTime!);
      case GroupType.month:
        return DateTime.fromMicrosecondsSinceEpoch(first.creationTime!).year ==
                DateTime.fromMicrosecondsSinceEpoch(second.creationTime!)
                    .year &&
            DateTime.fromMicrosecondsSinceEpoch(first.creationTime!).month ==
                DateTime.fromMicrosecondsSinceEpoch(second.creationTime!).month;
      case GroupType.year:
        return DateTime.fromMicrosecondsSinceEpoch(first.creationTime!).year ==
            DateTime.fromMicrosecondsSinceEpoch(second.creationTime!).year;
      case GroupType.week:
        final firstDate =
            DateTime.fromMicrosecondsSinceEpoch(first.creationTime!);
        final secondDate =
            DateTime.fromMicrosecondsSinceEpoch(second.creationTime!);
        return areDatesInSameWeek(firstDate, secondDate);
      default:
        throw UnimplementedError("not implemented for $this");
    }
  }

  String _getDayTitle(BuildContext context, int timestamp) {
    final date = DateTime.fromMicrosecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month) {
      if (date.day == now.day) {
        return S.of(context).dayToday;
      } else if (date.day == now.day - 1) {
        return S.of(context).dayYesterday;
      }
    }
    if (date.year != DateTime.now().year) {
      return DateFormat.yMMMEd(Localizations.localeOf(context).languageCode)
          .format(date);
    } else {
      return DateFormat.MMMEd(Localizations.localeOf(context).languageCode)
          .format(date);
    }
  }
}
