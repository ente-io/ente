import "package:flutter/cupertino.dart";
import "package:intl/intl.dart";
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";

class DayWidget extends StatelessWidget {
  final int timestamp;
  final int gridSize;

  const DayWidget({
    super.key,
    required this.timestamp,
    required this.gridSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final textStyle =
        gridSize < photoGridSizeMax ? textTheme.body : textTheme.small;
    final double horizontalPadding = gridSize < photoGridSizeMax ? 12.0 : 8.0;
    final double verticalPadding = gridSize < photoGridSizeMax ? 12.0 : 14.0;
    final String dayTitle = _getDayTitle(context, timestamp);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Container(
        alignment: Alignment.centerLeft,
        child: Text(
          dayTitle,
          style: (dayTitle == S.of(context).dayToday)
              ? textStyle
              : textStyle.copyWith(color: colorScheme.textMuted),
        ),
      ),
    );
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
