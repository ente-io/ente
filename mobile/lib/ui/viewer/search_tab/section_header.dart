import "package:flutter/material.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/result/search_section_all_page.dart";
import "package:photos/utils/navigation_util.dart";

class SectionHeader extends StatelessWidget {
  final SectionType sectionType;
  final bool hasMore;
  const SectionHeader(this.sectionType, {required this.hasMore, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (hasMore) {
          routeToPage(
            context,
            SearchSectionAllPage(
              sectionType: sectionType,
            ),
          );
        }
      },
      child: Row(
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
              ? Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
                    child: Icon(
                      Icons.chevron_right_outlined,
                      color: getEnteColorScheme(context).blurStrokePressed,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
