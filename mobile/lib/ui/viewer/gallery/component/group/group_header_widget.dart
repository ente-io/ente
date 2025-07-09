import "package:flutter/widgets.dart";
import 'package:photos/core/constants.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";

class GroupHeaderWidget extends StatelessWidget {
  final String title;
  final int gridSize;
  final double? height;

  const GroupHeaderWidget({
    super.key,
    required this.title,
    required this.gridSize,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final textStyle =
        gridSize < photoGridSizeMax ? textTheme.body : textTheme.small;
    final double horizontalPadding = gridSize < photoGridSizeMax ? 12.0 : 8.0;
    final double verticalPadding = gridSize < photoGridSizeMax ? 12.0 : 14.0;

    return SizedBox(
      height: height,
      child: Padding(
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
            maxLines: 1,
            // TODO: Make it possible to see the full title if overflowing
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
