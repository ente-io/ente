import "package:flutter/material.dart";
import 'package:flutter/widgets.dart';
import 'package:photos/theme/ente_theme.dart';

class ChangeLogEntry {
  final bool isFeature;
  final String title;
  final String description;

  ChangeLogEntry(this.title, this.description, {this.isFeature = true});
}

class ChangeLogEntryWidget extends StatelessWidget {
  final ChangeLogEntry entry;

  const ChangeLogEntryWidget({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enteTheme = EnteTheme.getTextTheme(theme);
    final colorScheme = EnteTheme.getColorScheme(theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.title,
          textAlign: TextAlign.left,
          style: enteTheme.largeBold.copyWith(
            color: entry.isFeature
                ? colorScheme.primary700
                : colorScheme.textMuted,
          ),
        ),
        const SizedBox(
          height: 18,
        ),
        Text(
          entry.description,
          textAlign: TextAlign.left,
          style: enteTheme.body.copyWith(
            color: colorScheme.textMuted,
          ),
        ),
        const SizedBox(
          height: 18,
        ),
      ],
    );
  }
}
