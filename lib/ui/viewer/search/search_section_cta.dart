import "package:flutter/material.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";

class SearchSectionCTAIcon extends StatelessWidget {
  final SectionType sectionType;

  const SearchSectionCTAIcon(this.sectionType, {super.key});

  @override
  Widget build(BuildContext context) {
    if (sectionType.isCTAVisible == false) {
      return const SizedBox.shrink();
    }
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colorScheme.strokeFaint,
                width: 1,
              ),
            ),
            child: Icon(
              sectionType.getCTAIcon() ?? Icons.add,
              color: colorScheme.strokeFaint,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          sectionType.getCTAText(context),
          style: textTheme.miniFaint,
        )
      ],
    );
  }
}
