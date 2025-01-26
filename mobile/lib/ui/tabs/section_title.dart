import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';
import "package:styled_text/styled_text.dart";

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
    final enteTextTheme = getEnteTextTheme(context);
    Widget child;
    if (titleWithBrand != null) {
      child = titleWithBrand!;
    } else if (title != null) {
      child = Text(
        title!,
        style: mutedTitle ? enteTextTheme.bodyMuted : enteTextTheme.largeBold,
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: Alignment.centerLeft,
      padding: padding,
      child: child,
    );
  }
}

class SectionOptions extends StatelessWidget {
  final Widget title;
  final Widget? trailingWidget;
  final EdgeInsetsGeometry? padding;

  const SectionOptions(
    this.title, {
    this.trailingWidget,
    this.padding = const EdgeInsets.only(left: 12, right: 0),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (trailingWidget != null) {
      return Container(
        padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(alignment: Alignment.centerLeft, child: title),
            trailingWidget!,
          ],
        ),
      );
    } else {
      return Container(
        alignment: Alignment.centerLeft,
        padding: padding,
        child: title,
      );
    }
  }
}

Widget getOnEnteSection(BuildContext context) {
  final EnteTextTheme textTheme = getEnteTextTheme(context);

  return StyledText(
    text: S.of(context).onEnte,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
      fontSize: 21,
      color: textTheme.brandSmall.color,
    ),
    tags: {
      'branding': StyledTextTag(
        style: textTheme.brandSmall,
      ),
    },
  );
}
