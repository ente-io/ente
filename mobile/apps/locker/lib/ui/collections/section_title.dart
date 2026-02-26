import "package:ente_ui/theme/ente_theme.dart";
import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String? title;
  final bool mutedTitle;
  final Widget? titleWithBrand;
  final EdgeInsetsGeometry? padding;

  const SectionTitle({
    this.title,
    this.titleWithBrand,
    this.mutedTitle = false,
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (titleWithBrand != null) {
      child = titleWithBrand!;
    } else if (title != null) {
      child = Text(
        title!,
        style: getEnteTextTheme(context).h3Bold,
      );
    } else {
      child = const SizedBox.shrink();
    }
    return child;
  }
}

class SectionOptions extends StatelessWidget {
  final Widget title;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final String? body;

  const SectionOptions(
    this.title, {
    this.trailingWidget,
    super.key,
    this.body,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (trailingWidget != null) {
      final hasBody = body != null && body!.isNotEmpty;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                title,
                trailingWidget!,
              ],
            ),
            if (hasBody)
              Text(
                body!,
                style: getEnteTextTheme(context).bodyMuted,
              ),
          ],
        ),
      );
    } else {
      return Container(
        child: title,
      );
    }
  }
}
