import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class TitleBarTitleWidget extends StatelessWidget {
  final String? title;
  final bool isTitleH2;
  final IconData? icon;
  final List<Widget>? trailingWidgets;
  const TitleBarTitleWidget({
    super.key,
    this.title,
    this.isTitleH2 = false,
    this.icon,
    this.trailingWidgets,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorTheme = getEnteColorScheme(context);
    if (title != null) {
      Widget titleWidget;
      if (icon != null) {
        titleWidget = Row(
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
      } else if (isTitleH2) {
        titleWidget = Text(
          title!,
          style: textTheme.h2Bold,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      } else {
        titleWidget = Text(
          title!,
          style: textTheme.h3Bold,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      }

      if (trailingWidgets != null && trailingWidgets!.isNotEmpty) {
        return Row(
          children: [
            Expanded(child: titleWidget),
            ...trailingWidgets!,
          ],
        );
      }
      return titleWidget;
    }

    return const SizedBox.shrink();
  }
}
