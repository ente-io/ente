import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/theme/text_style.dart';

class SectionTitle extends StatelessWidget {
  final String? title;
  final RichText? titleWithBrand;

  const SectionTitle({
    this.title,
    this.titleWithBrand,
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 0, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ],
      ),
    );
  }
}

RichText onEnteSection = RichText(
  text: const TextSpan(
    children: [
      TextSpan(
        text: "On ",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
          fontSize: 21,
        ),
      ),
      TextSpan(text: "ente", style: brandStyleSmall),
    ],
  ),
);
