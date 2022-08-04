import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/search/location_collection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class LocationResultsWidget extends StatelessWidget {
  final Map<String, List<File>> locationToMatchedFiles;
  const LocationResultsWidget(this.locationToMatchedFiles, {Key key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    int noOfMemories = locationToMatchedFiles.values.first.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
                    locationToMatchedFiles.keys.first,
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
            SizedBox(
              height: 50,
              width: 50,
              child: ThumbnailWidget(locationToMatchedFiles.values.first[0]),
            ),
          ],
        ),
      ),
      onTap: () {
        routeToPage(
          context,
          LocationCollectionPage(
            files: locationToMatchedFiles.values.first,
          ),
        );
      },
    );
  }
}
