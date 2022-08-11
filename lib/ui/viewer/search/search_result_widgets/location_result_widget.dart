import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/location_search_result.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/search/collections/files_in_location_page.dart';
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locationSearchResult.location,
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.defaultTextColor,
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
              ),
              Hero(
                tag: heroTagPrefix + locationSearchResult.files[0].tag(),
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: ThumbnailWidget(locationSearchResult.files[0]),
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        routeToPage(
          context,
          FilesInLocationPage(locationSearchResult, heroTagPrefix),
          forceCustomPageRoute: true,
        );
      },
    );
  }
}
