import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/year_search_result.dart';
import 'package:photos/ui/viewer/search/collections/files_from_year_page.dart';
import 'package:photos/ui/viewer/search/search_result_widgets/search_result_thumbnail_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class YearSearchResultWidget extends StatelessWidget {
  static const String _tagPrefix = "year_search";

  final YearSearchResult yearSearchResult;
  const YearSearchResultWidget(this.yearSearchResult, {Key key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final noOfMemories = yearSearchResult.files.length;
    final heroTagPrefix = _tagPrefix + yearSearchResult.year.toString();

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
              SearchResultThumbnailWidget(
                yearSearchResult.files[0],
                heroTagPrefix,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.subTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    yearSearchResult.year.toString(),
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
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
          FilesFromYearPage(yearSearchResult, heroTagPrefix),
        );
      },
    );
  }
}
