import 'package:flutter/widgets.dart';
import 'package:photos/theme/ente_theme.dart';

class ChangeLogEntry {
  final bool isFeature;
  final String title;
  final String? description;
  final List<String> items;

  ChangeLogEntry(
    this.title, {
    this.description,
    this.items = const [],
    this.isFeature = true,
  });
}

class ChangeLogEntryWidget extends StatelessWidget {
  final ChangeLogEntry entry;

  const ChangeLogEntryWidget({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final enteTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final hasDescription =
        entry.description != null && entry.description!.isNotEmpty;
    final hasItems = entry.items.isNotEmpty;

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
        if (hasDescription)
          Padding(
            padding: EdgeInsets.only(bottom: hasItems ? 12 : 0),
            child: Text(
              entry.description!,
              textAlign: TextAlign.left,
              style: enteTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
            ),
          ),
        ...entry.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: enteTheme.body.copyWith(
                    color: colorScheme.textMuted,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    textAlign: TextAlign.left,
                    style: enteTheme.body.copyWith(
                      color: colorScheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
      ],
    );
  }
}
