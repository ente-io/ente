import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class TitleBarTitleWidget extends StatelessWidget {
  final String? title;
  final bool isTitleH2;
  final IconData? icon;
  const TitleBarTitleWidget(
      {this.title, this.isTitleH2 = false, this.icon, super.key});

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
            Text(title!, style: textTheme.h3Bold),
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: colorTheme.strokeMuted),
          ],
        );
      }
      if (isTitleH2) {
        return Text(title!, style: textTheme.h2Bold);
      } else {
        return Text(title!, style: textTheme.h3Bold);
      }
    }

    return const SizedBox.shrink();
  }
}
