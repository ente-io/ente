import "package:flutter/material.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/theme/ente_theme.dart";

class EmptyOnEnteSection extends StatelessWidget {
  final List<Collection> collections;

  const EmptyOnEnteSection({
    super.key,
    required this.collections,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final sampleNames = collections
        .map((collection) => collection.displayName)
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();
    final countText = "You have ${collections.length} album"
        "${collections.length == 1 ? "" : "s"} on Ente.";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.fillFaint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.strokeFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Offline mode",
            style: textTheme.smallBold.copyWith(color: colorScheme.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            countText,
            style: textTheme.body.copyWith(color: colorScheme.textBase),
          ),
          const SizedBox(height: 6),
          Text(
            "Sign in to view and manage albums stored on Ente.",
            style: textTheme.small.copyWith(color: colorScheme.textMuted),
          ),
          if (sampleNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sampleNames
                  .map(
                    (name) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.fillBase,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colorScheme.strokeFaint),
                      ),
                      child: Text(
                        name,
                        style: textTheme.mini.copyWith(
                          color: colorScheme.textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
