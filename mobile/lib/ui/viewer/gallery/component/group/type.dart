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
    }
    throw UnimplementedError("not implemented for $this");
  }

  bool areFromSameGroup(EnteFile first, EnteFile second) {
    switch (this) {
      case GroupType.day:
        return areFromSameDay(first.creationTime!, second.creationTime!);
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
