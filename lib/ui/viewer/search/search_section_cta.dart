import "package:dotted_border/dotted_border.dart";
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
    return GestureDetector(
      onTap: sectionType.ctaOnTap(context),
      child: SizedBox(
        width: 84,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DottedBorder(
                color: colorScheme.strokeFaint,
                dashPattern: const [3.875, 3.875],
                borderType: BorderType.Circle,
                strokeWidth: 1.5,
                radius: const Radius.circular(33.25),
                child: SizedBox(
                  width: 62.5,
                  height: 62.5,
                  child: Icon(
                    sectionType.getCTAIcon() ?? Icons.add,
                    color: colorScheme.strokeFaint,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(
                height: 9.25,
              ),
              Text(
                sectionType.getCTAText(context),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: textTheme.miniFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
