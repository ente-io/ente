import "package:flutter/cupertino.dart";
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/utils/date_time_util.dart";

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
    final String dayTitle = getDayTitle(context, timestamp);
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
}
