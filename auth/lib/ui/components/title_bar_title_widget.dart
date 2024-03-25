import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class TitleBarTitleWidget extends StatelessWidget {
  final String? title;
  final bool isTitleH2;
  final IconData? icon;
  const TitleBarTitleWidget({
    super.key,
    this.title,
    this.isTitleH2 = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorTheme = getEnteColorScheme(context);
    if (title != null) {
      if (icon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title!,
              style: textTheme.h3Bold,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: colorTheme.strokeMuted),
          ],
        );
      }
      if (isTitleH2) {
        return Text(
          title!,
          style: textTheme.h2Bold,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      } else {
        return Text(
          title!,
          style: textTheme.h3Bold,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }
    }

    return const SizedBox.shrink();
  }
}
