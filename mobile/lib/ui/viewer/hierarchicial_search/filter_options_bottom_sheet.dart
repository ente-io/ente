import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/models/search/hierarchical/face_filter.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/hierarchicial_search/filter_chip.dart";

class FilterOptionsBottomSheet extends StatelessWidget {
  final SearchFilterDataProvider searchFilterDataProvider;
  const FilterOptionsBottomSheet(
    this.searchFilterDataProvider, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final recommendations = searchFilterDataProvider.recommendations;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: SizedBox(
        height: kFilterChipHeight,
        child: ListView.builder(
          itemBuilder: (context, index) {
            final filter = recommendations[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: filter is FaceFilter
                  ? FaceFilterChip(
                      personId: filter.personId,
                      clusterId: filter.clusterId,
                      faceThumbnailFile: filter.faceFile,
                      name: filter.name(),
                      apply: () {
                        searchFilterDataProvider.applyFilters([filter]);
                      },
                      remove: () {
                        searchFilterDataProvider.removeAppliedFilters([filter]);
                      },
                      isApplied: filter.isApplied,
                    )
                  : GenericFilterChip(
                      label: filter.name(),
                      apply: () {
                        searchFilterDataProvider.applyFilters([filter]);
                      },
                      remove: () {
                        searchFilterDataProvider.removeAppliedFilters([filter]);
                      },
                      leadingIcon: filter.icon(),
                      isApplied: filter.isApplied,
                    ),
            );
          },
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          itemCount: recommendations.length,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}
