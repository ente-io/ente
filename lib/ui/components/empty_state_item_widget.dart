import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";

class EmptyStateItemWidget extends StatelessWidget {
  final String textContent;
  const EmptyStateItemWidget(this.textContent, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_outlined,
          size: 17,
          color: colorScheme.strokeFaint,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            textContent,
            style: textTheme.small.copyWith(
              color: colorScheme.textFaint,
            ),
          ),
        ),
      ],
    );
  }
}
