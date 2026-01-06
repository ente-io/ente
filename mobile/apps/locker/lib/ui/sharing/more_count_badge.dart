import "package:ente_ui/theme/ente_theme.dart";
import 'package:flutter/material.dart';
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

    final Color decorationColor = colorScheme.avatarColors[1];

    final avatarStyle = getAvatarStyle(context, type);
    final double size = avatarStyle.item1;
    final TextStyle textStyle = avatarStyle.item2.copyWith(color: Colors.white);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: getEnteColorScheme(context).backdropBase,
          width: 1.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: SizedBox(
        height: size,
        width: size,
        child: CircleAvatar(
          backgroundColor: decorationColor,
          child: Transform.scale(
            scale: 0.85,
            child: Text(
              displayChar.toUpperCase(),
              style: textStyle,
            ),
          ),
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
        return Tuple2(32.0, enteTextTheme.small);
      case MoreCountType.mini:
        return Tuple2(24.0, enteTextTheme.mini);
      case MoreCountType.tiny:
        return Tuple2(18.0, enteTextTheme.tiny);
      case MoreCountType.extra:
        return Tuple2(18.0, enteTextTheme.tiny);
    }
  }
}
