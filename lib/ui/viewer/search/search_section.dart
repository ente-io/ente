import "package:flutter/material.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/search_section_cta.dart";

class SearchSection extends StatelessWidget {
  final SectionType sectionType;

  const SearchSection({
    Key? key,
    required this.sectionType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint("Building section for ${sectionType.name}");
    final textTheme = getEnteTextTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionType.sectionTitle(context),
                  style: textTheme.largeBold,
                ),
                const SizedBox(height: 16),
                // wrap below text in next line
                Text(
                  sectionType.getEmptyStateText(context),
                  style: textTheme.smallMuted,
                  softWrap: true,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 85,
            child: SearchSectionCTAIcon(sectionType),
          )
        ],
      ),
    );
  }
}
