import "package:flutter/material.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";

class SectionHeader extends StatelessWidget {
  final SectionType sectionType;
  final bool hasMore;
  const SectionHeader(this.sectionType, {required this.hasMore, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            sectionType.sectionTitle(context),
            style: getEnteTextTheme(context).largeBold,
          ),
        ),
        hasMore
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.chevron_right_outlined,
                  color: getEnteColorScheme(context).strokeMuted,
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
