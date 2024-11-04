import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:tuple/tuple.dart';

enum MoreCountType { small, mini, tiny, extra }

class MoreCountWidget extends StatelessWidget {
  final MoreCountType type;
  final bool thumbnailView;
  final int count;

  const MoreCountWidget(
    this.count, {
    super.key,
    this.type = MoreCountType.mini,
    this.thumbnailView = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final displayChar = "+$count";
    final Color decorationColor = thumbnailView
        ? backgroundElevated2Light
        : colorScheme.backgroundElevated2;

    final avatarStyle = getAvatarStyle(context, type);
    final double size = avatarStyle.item1;
    final TextStyle textStyle = thumbnailView
        ? avatarStyle.item2.copyWith(color: textFaintLight)
        : avatarStyle.item2.copyWith(color: Colors.white);
    return Container(
      height: size,
      width: size,
      padding: thumbnailView
          ? const EdgeInsets.only(bottom: 1)
          : const EdgeInsets.all(2),
      decoration: thumbnailView
          ? null
          : BoxDecoration(
              shape: BoxShape.circle,
              color: decorationColor,
              border: Border.all(
                color: strokeBaseDark,
                width: 1.0,
              ),
            ),
      child: CircleAvatar(
        backgroundColor: decorationColor,
        child: Text(
          displayChar.toUpperCase(),
          // fixed color
          style: textStyle,
        ),
      ),
    );
  }

  Tuple2<double, TextStyle> getAvatarStyle(
    BuildContext context,
    MoreCountType type,
  ) {
    final enteTextTheme = getEnteTextTheme(context);
    switch (type) {
      case MoreCountType.small:
        return Tuple2(36.0, enteTextTheme.small);
      case MoreCountType.mini:
        return Tuple2(24.0, enteTextTheme.mini);
      case MoreCountType.tiny:
        return Tuple2(18.0, enteTextTheme.tiny);
      case MoreCountType.extra:
        return Tuple2(18.0, enteTextTheme.tiny);
    }
  }
}
