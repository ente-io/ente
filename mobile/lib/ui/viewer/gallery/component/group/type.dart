import "package:flutter/widgets.dart";
import "package:intl/intl.dart";
import "package:photos/core/constants.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/utils/standalone/date_time.dart";

enum GroupType {
  day,
  week,
  month,
  size,
  year,
  none,
}

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
      case GroupType.none:
        return "none";
    }
  }

  bool timeGrouping() {
    return this == GroupType.day ||
        this == GroupType.week ||
        this == GroupType.month ||
        this == GroupType.year;
  }

  bool showGroupHeader() {
    if (this == GroupType.size || this == GroupType.none) {
      return false;
    }
    return true;
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
    } else if (this == GroupType.month) {
      final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
      return DateFormat.yMMM(Localizations.localeOf(context).languageCode)
          .format(date);
    } else {
      throw UnimplementedError("getTitle not implemented for $this");
    }
  }

  // returns true if the group should be refreshed.
  // If groupType is day, it should return true if the list of modified files contains a file that was created on the same day as the first file.
  // If groupType is week, it should return true if the list of modified files contains a file that was created in the same week as the first file.
  // If groupType is month, it should return true if the list of modified files contains a file that was created in the same month as the first file.
  // If groupType is year, it should return true if the list of modified files contains a file that was created in the same year as the first file.
  bool areModifiedFilesPartOfGroup(
    List<EnteFile> modifiedFiles,
    EnteFile fistFile, {
    EnteFile? lastFile,
  }) {
    switch (this) {
      case GroupType.day:
        return modifiedFiles.any(
          (file) => areFromSameDay(fistFile.creationTime!, file.creationTime!),
        );
      case GroupType.week:
        return modifiedFiles.any((file) {
          final firstDate =
              DateTime.fromMicrosecondsSinceEpoch(fistFile.creationTime!);
          final fileDate =
              DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
          return areDatesInSameWeek(firstDate, fileDate);
        });
      case GroupType.month:
        return modifiedFiles.any((file) {
          final firstDate =
              DateTime.fromMicrosecondsSinceEpoch(fistFile.creationTime!);
          final fileDate =
              DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
          return firstDate.year == fileDate.year &&
              firstDate.month == fileDate.month;
        });
      case GroupType.year:
        return modifiedFiles.any((file) {
          final firstDate =
              DateTime.fromMicrosecondsSinceEpoch(fistFile.creationTime!);
          final fileDate =
              DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
          return firstDate.year == fileDate.year;
        });
      default:
        throw UnimplementedError("not implemented for $this");
    }
  }

  // for day, year, month, year type, return the microsecond range of the group
  (int, int) getGroupRange(EnteFile file) {
    switch (this) {
      case GroupType.day:
        final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final startOfDay = DateTime(date.year, date.month, date.day);
        return (
          startOfDay.microsecondsSinceEpoch,
          (startOfDay.microsecondsSinceEpoch + microSecondsInDay - 1),
        );
      case GroupType.week:
        final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final startOfWeek = DateTime(date.year, date.month, date.day)
            .subtract(Duration(days: date.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return (
          startOfWeek.microsecondsSinceEpoch,
          endOfWeek.microsecondsSinceEpoch - 1
        );
      case GroupType.month:
        final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final startOfMonth = DateTime(date.year, date.month);
        final endOfMonth = DateTime(date.year, date.month + 1);
        return (
          startOfMonth.microsecondsSinceEpoch,
          endOfMonth.microsecondsSinceEpoch - 1
        );
      case GroupType.year:
        final date = DateTime.fromMicrosecondsSinceEpoch(file.creationTime!);
        final startOfYear = DateTime(date.year);
        final endOfYear = DateTime(date.year + 1);
        return (
          startOfYear.microsecondsSinceEpoch,
          endOfYear.microsecondsSinceEpoch - 1
        );
      default:
        throw UnimplementedError("not implemented for $this");
    }
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
