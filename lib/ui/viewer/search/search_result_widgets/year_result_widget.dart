import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/year_search_result.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

class YearSearchResultWidget extends StatelessWidget {
  final YearSearchResult yearSearchResult;
  const YearSearchResultWidget(this.yearSearchResult, {Key key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final noOfMemories = yearSearchResult.files.length;
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
                      'Year',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      yearSearchResult.year.toString(),
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
                tag: "year_search" + yearSearchResult.files[0].tag(),
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: ThumbnailWidget(yearSearchResult.files[0]),
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        // routeToPage(
        //   context,
        //   FilesInLocationPage(
        //     yearSearchResult: yearSearchResult,
        //   ),
        // );
      },
    );
  }
}
