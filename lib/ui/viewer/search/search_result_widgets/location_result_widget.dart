import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/location_search_result.dart';
import 'package:photos/ui/viewer/search/collections/files_in_location_page.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/search_result_thumbnail_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class LocationSearchResultWidget extends StatelessWidget {
  static const String _tagPrefix = "location_search";

  final LocationSearchResult locationSearchResult;
  const LocationSearchResultWidget(this.locationSearchResult, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final noOfMemories = locationSearchResult.files.length;
    final heroTagPrefix = _tagPrefix + locationSearchResult.location;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Theme.of(context).colorScheme.searchResultsColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SearchResultThumbnailWidget(
                locationSearchResult.files[0],
                heroTagPrefix,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.subTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 220,
                    child: Text(
                      locationSearchResult.location,
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .searchResultsCountTextColor,
                      ),
                      children: [
                        TextSpan(text: noOfMemories.toString()),
                        TextSpan(
                          text: noOfMemories != 1 ? ' memories' : ' memory',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.subTextColor,
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        routeToPage(
          context,
          FilesInLocationPage(locationSearchResult, heroTagPrefix),
        );
      },
    );
  }
}
