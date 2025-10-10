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
      if (icon != null || trailingWidgets != null) {
        return Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title!,
                      style: textTheme.h3Bold,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20, color: colorTheme.strokeMuted),
                  ],
                ],
              ),
            ),
            if (trailingWidgets != null) ...[
              ...trailingWidgets!,
            ],
          ],
        );
      }
      if (isTitleH2) {
        final titleText = Text(
          title!,
          style: textTheme.h2Bold,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
        if (trailingWidgets != null) {
          return Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: titleText,
              ),
              ...trailingWidgets!,
            ],
          );
        }
        return titleText;
      } else {
        final titleText = Text(
          title!,
          style: textTheme.h3Bold,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
        if (trailingWidgets != null) {
          return Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: titleText,
              ),
              ...trailingWidgets!,
            ],
          );
        }
        return titleText;
      }
    }

    return const SizedBox.shrink();
  }
}
