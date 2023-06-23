import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';
import "package:styled_text/styled_text.dart";

class SectionTitle extends StatelessWidget {
  final String? title;
  final Widget? titleWithBrand;
  final bool skipMargin;

  const SectionTitle({
    this.title,
    this.titleWithBrand,
    this.skipMargin = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enteTextTheme = getEnteTextTheme(context);
    Widget child;
    if (titleWithBrand != null) {
      child = titleWithBrand!;
    } else if (title != null) {
      child = Text(
        title!,
        style: enteTextTheme.largeBold,
      );
    } else {
      child = const SizedBox.shrink();
    }
    return child;
  }
}

class SectionTitleRow extends StatelessWidget {
  final SectionTitle title;
  final Widget? trailingWidget;
  final EdgeInsetsGeometry? padding;

  const SectionTitleRow(
    this.title, {
    this.trailingWidget,
    this.padding = const EdgeInsets.only(left: 4, right: 4),
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
