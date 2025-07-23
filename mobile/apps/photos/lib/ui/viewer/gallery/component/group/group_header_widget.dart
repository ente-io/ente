import "package:flutter/cupertino.dart";
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";

class GroupHeaderWidget extends StatelessWidget {
  final String title;
  final int gridSize;

  const GroupHeaderWidget({
    super.key,
    required this.title,
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Container(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: (title == S.of(context).dayToday)
              ? textStyle
              : textStyle.copyWith(color: colorScheme.textMuted),
        ),
      ),
    );
  }
}
