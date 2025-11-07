import "package:dotted_border/dotted_border.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.assetPath,
    this.title,
    this.subtitle,
    this.onTap,
    this.showBorder = true,
    this.illustrationHeight,
    this.horizontalPadding = 24,
    this.verticalPadding = 42,
    this.spacing = 20,
  });

  final String assetPath;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showBorder;
  final double? illustrationHeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    final content = GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (assetPath.isNotEmpty)
              Image.asset(
                assetPath,
                height: illustrationHeight,
              ),
            if (assetPath.isNotEmpty) SizedBox(height: spacing),
            if (title != null && title!.isNotEmpty)
              Text(
                title!,
                style: textTheme.largeBold.copyWith(
                  color: colorScheme.textBase,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null && title!.isNotEmpty) const SizedBox(height: 12),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: textTheme.small.copyWith(
                  color: colorScheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );

    if (!showBorder) {
      return content;
    }

    return DottedBorder(
      options: const RoundedRectDottedBorderOptions(
        strokeWidth: 1,
        color: Color.fromRGBO(82, 82, 82, 0.6),
        dashPattern: [5, 5],
        radius: Radius.circular(24),
      ),
      child: content,
    );
  }
}
